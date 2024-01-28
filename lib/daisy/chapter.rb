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
    title || (book.chapters.size > 1 ? "Chapitre #{position}" : book.title)
  end

  #  Name of SMIL file for this chapter.
  def smil_file
    file.sub('.mp3', '.smil')
  end

  #  Entry in the ncc.html file for the chapter.
  def ncc_ref
    html = <<~HTML
      <h1 id="chapter_#{position}" class="section">
        <a href="#{smil_file}#read_#{position}">#{chapter_title.text_escape}</a>
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
          <par endsync="last" id="read_#{position}">
            <text src="ncc.html#chapter_#{position}" id="text_#{position}" />
            <audio src="#{file}" id="audio_#{position}" clip-begin="npt=0.000s" clip-end="npt=#{'%5.3f' % duration}s" />
          </par>
        </seq>
      </body>
      </smil>
    XML
  end

  TIDY_MP3 = "lame -a -t --strictly-enforce-ISO -b56 --resample 44.1"
  # -a  Downmix from stereo to mono file for mono encoding. Needed with RAW input for the -mm mode to do the downmix.
  # -t  Disable VBR informational tag
  # --strictly-enforce-ISO  Comply as much as possible to ISO MPEG spec
  # -bn The bitrate to be used. Default is 128kbps in MPEG1 (64 for mono), 64kbps in MPEG2 (32 for mono) and 32kbps in MPEG2.5 (16 for mono).
  #   Codec               sample frequencies (kHz)  bitrates (kbps)
  #   MPEG-1 layer III    32, 48, 44.1              32 40 48 56 64 80 96 112 128 160 192 224 256 320
  #   MPEG-2 layer III    16, 24, 22.05             8 16 24 32 40 48 56 64 80 96 112 128 144 160
  #   MPEG-2.5 layer III  8, 12, 11.025             8 16 24 32 40 48 56 64
  # --resample n Output sampling frequency in kHz
  #   n = 8, 11.025, 12, 16, 22.05, 24, 32, 44.1, 48
  #   Output sampling frequency. Resample the input if necessary.
  #
  #   If not specified, LAME may sometimes resample automatically when faced with extreme compression
  #   conditions (like encoding a 44.1 kHz input file at 32 kbps). To disable this automatic
  #   resampling, you have to use --resample to set the output sample rate equal to the input sample
  #   rate. In that case, LAME will not perform any extra computations.

  # --cbr   Enforce use of constant bitrate

  # ID3 tag Information
  # --tt title  Audio/song title (max 30 chars for version 1 tag)
  # --ta artist   Audio/song artist (max 30 chars for version 1 tag)
  # --tl album  Audio/song album (max 30 chars for version 1 tag)
  # --ty year   Audio/song year of issue (1 to 9999)
  # --tc comment  User-defined text (max 30 chars for v1 tag, 28 for v1.1)
  # --tn track[/total]  Audio/song track number and (optionally) the total number of tracks on the original recording.
  #   (track and total each 1 to 255. just the track number creates v1.1 tag, providing a total forces v2.0).
  # --tg genre  Audio/song genre (name or number in list)
  # --ti file   Audio/song albumArt (jpeg/png/gif file, 128KB max, v2.3)

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
