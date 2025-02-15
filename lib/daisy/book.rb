require_relative 'core_ext'
using Daisy::CoreExt

module Daisy

##
#  A whole book.

class Book

  # directory for source mp3 files
  attr_reader :source_dir

  # directory where the DAISY files will be stored
  attr_reader :target_dir

  # re-encode with lame?
  attr_reader :re_encode

  # array of Chapter objects, one by input mp3 file
  attr_reader :chapters

  # generated unique identifier
  attr_reader :identifier

  # book title
  attr_reader :title

  # book author
  attr_reader :creator

  # book narrator
  attr_reader :narrator

  # book language
  attr_reader :language

  # book publisher
  attr_reader :publisher

  # book rights
  attr_reader :rights

  # book source publisher
  attr_reader :source_publisher

  # book source edition
  attr_reader :source_edition

  # Creates a new Book:
  # - input mp3 files are in +source_dir+
  # - output mp3 files & daisy files will go to +target_dir+
  # - if +re_encode+ is true, each mp3 will be re-encoded using lame
  #
  # Raises an error if no mp3 file is found.
  def initialize(source_dir, target_dir, re_encode: false)
    @source_dir = source_dir
    @target_dir = target_dir
    @re_encode = re_encode

    @chapters = Dir["#{File.expand_path(source_dir)}/*.mp3"].map { |path| Chapter.new(self, path) }
    @chapters.empty? and raise Error, "no mp3 file in #{source_dir.inspect}"
    @chapters.sort_by!(&:file)
    @chapters.each.with_index(1) { |c, i| c.position = i }

    @identifier = SecureRandom.uuid
    read_book_info
  end

  # Reads the information in the <tt>daisy.yaml</tt> or <tt>daisy.yml</tt> file.
  private def read_book_info
    path = find_daisy_yaml_path

    begin
      tags = YAML.load_file(path)
    rescue => ex
      warn "could not read #{path.inspect}:"
      warn ex.message
      raise Error, 'cannot continue'
    end
    unless tags.is_a?(Hash)
      raise Error, "invalid content in #{path.inspect}"
    end

    @title = tags.delete('title')
    @creator = tags.delete('creator')
    @narrator = tags.delete('narrator') || 'narrateur inconnu'
    @language = tags.delete('language') || 'fr'
    @publisher = tags.delete('publisher') || 'éditeur inconnu'
    @rights = tags.delete('rights') || 'droits inconnus'
    @source_publisher = tags.delete('source publisher') || 'éditeur source inconnu'
    @source_edition = tags.delete('source edition') || 'édition source inconnue'

    tags.empty? or
      warn "invalid keys in #{path}: #{tags.keys.map(&:inspect).join(', ')}"

    @title && @creator or
      raise Error, "title & creator are required in #{path}"

  end

  # Returns the path to the <tt>daisy.yaml</tt> or <tt>daisy.yml</tt> file,
  # starting from #source_dir and going up. Raises an Error if
  # no such file.
  private def find_daisy_yaml_path
    start_dir = File.expand_path(source_dir)
    dir = start_dir
    path = nil
    loop do
      pattern = "#{dir}/daisy.{yaml,yml}"
      paths = Dir.glob(pattern)
      unless paths.empty?
        path = paths.first
        break
      end
      up = File.dirname(dir)
      break if up == dir
      dir = up
    end

    raise Error, "daisy.yaml/daisy.yml not found going up from #{start_dir}" unless path

    path
  end

  # total book duration from chapter durations
  def total_duration
    chapters.map(&:duration).sum
  end

  #  Create all the DAISY metadata for the book.
  def create_daisy
    puts "Creating DAISY format in #{target_dir}"
    puts "Title: #{title.inspect}"
    FileUtils.mkpath target_dir unless File.directory?(target_dir)
    write_ncc_html
    write_title_smil
    puts "Contents:"
    elapsed_time = 0.0
    chapters.each do |c|
      puts "- #{c.position}. #{c.chapter_title}"
      c.copy_mp3 re_encode: re_encode
      c.write_smil elapsed_time
      elapsed_time += c.duration
    end
    write_master_smil
  end

  #  Write the ncc.html file.
  private def write_ncc_html
    date = Time.now.strftime('%Y-%m-%d')
    depth = 1  # <hX> depth
    toc_items = 1 + chapters.size # title + chapters
    file_count = 3 + 2 * chapters.size # ncc.html + master.smil + title.smil + (chapter.smil, chapter.mp3)
    html = <<~HTML
      <?xml version="1.0" encoding="windows-1252"?>
      <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
      <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="#{language}" lang="#{language}">
      <head>
        <title>#{title.text_escape}</title>
        <meta http-equiv="Content-type" content="text/html; charset=windows-1252" />
        <meta name="dc:creator" content="#{creator.attr_escape}" />
        <meta name="dc:date" content="#{date}" scheme="yyyy-mm-dd" />
        <meta name="dc:format" content="Daisy 2.02" />
        <meta name="dc:identifier" content="#{identifier}" />
        <meta name="dc:language" content="#{language}" />
        <meta name="dc:publisher" content="#{publisher.attr_escape}" />
        <meta name="dc:rights" content="#{rights.attr_escape}" />
        <meta name="dc:title" content="#{title.attr_escape}" />
        <meta name="ncc:charset" content="windows-1252" />
        <meta name="ncc:multimediaType" content="audioNcc" />
        <meta name="ncc:pageFront" content="0" />
        <meta name="ncc:pageNormal" content="0" />
        <meta name="ncc:pageSpecial" content="0" />
        <meta name="ncc:tocItems" content="#{toc_items}" />
        <meta name="ncc:depth" content="#{depth}" />
        <meta name="ncc:files" content="#{file_count}" />
        <meta name="ncc:maxPageNormal" content="0" />
        <meta name="dc:source" content="#{title.attr_escape}" />
        <meta name="ncc:sourcePublisher" content="#{source_publisher.attr_escape}" />
        <meta name="ncc:sourceDate" content="#{date}" scheme="yyyy-mm-dd" />
        <meta name="ncc:sourceEdition" content="#{source_edition.attr_escape}" />
        <meta name="ncc:narrator" content="#{narrator.attr_escape}" />
        <meta name="dc:subject" content="#{title.attr_escape}" />
        <meta name="ncc:totalTime" content="#{total_duration.to_hh(decimals: false)}" scheme="hh:mm:ss" />
      </head>
      <body>
        <h1 class="title" id="book_title"><a href="title.smil#read_title">#{title.text_escape}</a></h1>
    HTML

    chapters.each { |c| html << c.ncc_ref }

    html << <<~HTML
      </body>
      </html>
    HTML

    File.write "#{target_dir}/ncc.html", html, mode: 'wb:windows-1252'
  end

  #  Write the title.smil file.
  private def write_title_smil
    xml = <<~XML
      <?xml version="1.0" encoding="windows-1252"?>
      <!DOCTYPE smil PUBLIC "-//W3C//DTD SMIL 1.0//EN" "http://www.w3.org/TR/REC-SMIL/SMIL10.dtd">
      <smil>
        <head>
          <meta name="dc:format" content="Daisy 2.02" />
          <meta name="dc:title" content="#{title.attr_escape}" />
          <meta name="title" content="#{title.attr_escape}" />
          <meta name="dc:identifier" content="#{identifier}" />
          <meta name="ncc:totalElapsedTime" content="0:00:00" />
          <meta name="ncc:timeInThisSmil" content="0:00:00" />
          <layout>
            <region id="txtView" />
          </layout>
        </head>
        <body>
          <seq dur="0.000s">
            <par endsync="last" id="read_title">
              <text src="ncc.html#book_title" id="text_title" />
            </par>
          </seq>
        </body>
      </smil>
    XML

    File.write "#{target_dir}/title.smil", xml, mode: 'wb:windows-1252'
  end

  #  Write the master.smil file.
  private def write_master_smil
    xml = <<~XML
      <?xml version="1.0" encoding="windows-1252"?>
      <!DOCTYPE smil PUBLIC "-//W3C//DTD SMIL 1.0//EN" "http://www.w3.org/TR/REC-SMIL/SMIL10.dtd">
      <smil>
      <head>
        <meta name="dc:format" content="Daisy 2.02" />
        <meta name="dc:title" content="#{title.attr_escape}" />
        <meta name="dc:identifier" content="#{identifier}" />
        <meta name="ncc:timeInThisSmil" content="#{total_duration.to_hh}" />
        <layout><region id="txtView" /></layout>
      </head>
      <body>
        <ref title="#{title.attr_escape}" src="title.smil" id="Master_Title" />
    XML

    chapters.each { |c| xml << "  #{c.smil_ref}\n" }

    xml << <<~XML
      </body>
      </smil>
    XML

    File.write "#{target_dir}/master.smil", xml, mode: 'wb:windows-1252'
  end

end
end