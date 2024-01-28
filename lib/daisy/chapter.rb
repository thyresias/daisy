require_relative 'core_ext'
using Daisy::CoreExt

module Daisy

##
#  A chapter of a book.

class Chapter

  attr_reader :book       # parent Book instance
  attr_reader :file       # base mp3 file name

  attr_reader :album      # mp3 tag "album"
  attr_reader :title      # mp3 tag "title"
  attr_reader :author     # mp3 tag "artist"
  attr_reader :track      # mp3 tag "tracknum"
  attr_reader :duration   # mp3 duration (Float, seconds)

  attr_accessor :position # assigned by the book

  def initialize(book, path)
    @book = book
    @file = File.basename(path)
    read_mp3_tags
  end

  # Read ID3 tags from mp3 file.
  private def read_mp3_tags
    path = "#{book.source_dir}/#{file}"
    Mp3Info.open(path) do |i|
      @title    = i.tag.title
      @artist   = i.tag.artist
      @album    = i.tag.album
      @track    = i.tag.tracknum  # Integer
      @duration = i.length   # Float (seconds)
    end
  end

  def chapter_title
    title || (book.chapters.size > 1 ? "Chapter #{position}" : book.title)
  end

  #  Name of SMIL file for this chapter.
  def smil_file
    file.sub('.mp3', '.smil')
  end

  #  Entry in the ncc.html file for the chapter.
  def ncc_ref
    html = <<~HTML
      <h1 id="Chapter_#{position}" class="section">
        <a href="#{smil_file}#Read_#{position}">#{chapter_title.text_escape}</a>
      </h1>
    HTML

    html.lines.map { |line| "  #{line}" }.join
  end

  #  Entry in the master.smil file for the chapter.
  def smil_ref
    %(<ref title="#{chapter_title.attr_escape}" src="#{smil_file.attr_escape}" id="Master_#{position}"/>)
  end

  #  Write the chapter smil_file file.
  def write_smil(elapsed_time)
    File.write "#{book.target_dir}/#{smil_file}", <<~XML, mode: 'wb:windows-1252'
      <?xml version="1.0" encoding="windows-1252"?>
      <!DOCTYPE smil PUBLIC "-//W3C//DTD SMIL 1.0//EN" "http://www.w3.org/TR/REC-SMIL/SMIL10.dtd">
      <smil>
      <head>
        <meta name="dc:format" content="Daisy 2.02" />
        <meta name="dc:title" content="#{book.title.attr_escape}" />
        <meta name="dc:identifier" content="#{book.identifier}" />
        <meta name="title" content="#{chapter_title.attr_escape}" />
        <meta name="ncc:totalElapsedTime" content="#{elapsed_time.to_hh}" />
        <meta name="ncc:timeInThisSmil" content="#{duration.to_hh}" />
        <layout>
          <region id="txtView" />
        </layout>
      </head>
      <body>
        <seq dur="#{'%5.3f' % duration}s">
          <par endsync="last" id="Read_#{position}">
            <text src="ncc.html#Chapter_#{position}" id="Text_#{position}" />
            <audio src="#{file}" id="Audio_#{position}" clip-begin="npt=0.000s" clip-end="npt=#{'%5.3f' % duration}s" />
          </par>
        </seq>
      </body>
      </smil>
    XML
  end

  TIDY_MP3 = "lame -a -t --strictly-enforce-ISO -b56 --resample 44.1"

  def copy_mp3(re_encode: false)
    source = "#{book.source_dir}/#{file}"
    target = "#{book.target_dir}/#{file}"
    File.delete target if File.exist?(target)
    if re_encode
      puts "re-encoding #{file}"
      system "#{TIDY_MP3} #{source.inspect} #{target.inspect}"
    else
      FileUtils.cp source, target
    end
  end

end
end
