module Daisy

##
# Command line interpreter.

class CLI

  attr_reader :command_name

  attr_reader :re_encode
  attr_reader :short_stories
  attr_reader :source_dir
  attr_reader :target_dir

  def initialize(command_name)
    @command_name = command_name
  end

  def run
    parse_arguments
    begin
      book = Book.new(source_dir, target_dir, re_encode: re_encode, short_stories: short_stories)
      book.create_daisy
    rescue Error => ex
      warn ex.message
      exit
    end
  end

  def usage
    puts <<~EOT.lines.map { |t| "  #{t}" }

      #{command_name} [OPTIONS] [SOURCE] [TARGET]

      OPTIONS
      -h, --help            display this text and exit
      -e, --re-encode       re-encode mp3 files with lame
      -s, --short-stories   short stories
      --                    end of options

      SOURCE  source directory, '.' by default
      TARGET  target directory, 'SOURCE/daisy' by default

      The source directory or one of its parents must contain a "daisy.yaml" or "daisy.yml" file.
      In this file, the first 2 keys are required:
      ---
      title: book title
      creator: book author
      narrator: narrator name
      language: 2-letter ISO code like "fr", "en", etc.
      publisher: ...
      rights: license terms or rights owner
      source publisher: ...
      source edition: ...
    EOT
    exit
  end

  def parse_arguments

    @re_encode = false
    @short_stories = false

    while ARGV.first && ARGV.first[0] == '-'
      opt = ARGV.shift
      case opt
      when '-h', '--help' then usage
      when '-e', '--re-encode' then @re_encode = true
      when '-s', '--short-stories' then @short_stories = true
      when '--' then break
      else warn "invalid option #{opt.inspect}, ignored"
      end
    end

    @source_dir = ARGV.shift || '.'
    @target_dir = ARGV.shift || "#{source_dir}/daisy"

    unless ARGV.empty?
      warn "extra arguments ignored: #{ARGV.map(&:inspect).join(', ')}"
    end

  end

end
end