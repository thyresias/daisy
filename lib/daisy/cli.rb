module Daisy

##
# Command line interpreter.

class CLI

  # name of the command
  attr_reader :command_name

  # re-encode option
  attr_reader :re_encode

  # source directory
  attr_reader :source_dir

  # target directory
  attr_reader :target_dir

  # Creates the interpreter for a command named +command_name+.
  def initialize(command_name)
    @command_name = command_name
  end

  # Runs the interpreter.
  def run
    parse_arguments
    begin
      book = Book.new(source_dir, target_dir, re_encode: re_encode)
      book.create_daisy
    rescue Error => ex
      warn ex.message
      exit
    end
  end

  # Displays the command usage and exits.
  def usage
    puts <<~EOT.lines.map { |t| "  #{t}" }

      #{command_name} [OPTIONS] [SOURCE] [TARGET]

      OPTIONS
      -h, --help        display this text and exit
      -e, --re-encode   re-encode mp3 files with lame
      --                end of options

      SOURCE  source directory, '.' by default
      TARGET  target directory, 'SOURCE/daisy' by default

      The source directory or one of its parents must contain a "daisy.yaml" or "daisy.yml" file.
      In this file, the first 2 keys are required:
      ---
      title: book title
      creator: book author
      narrator: narrator name
      language: ISO code like "fr", "fr-CA", "en", etc.
      publisher: ...
      rights: license terms or rights owner
      source publisher: ...
      source edition: ...
    EOT
    exit
  end

  # Parses the options and command line arguments.
  private def parse_arguments

    @re_encode = false

    while ARGV.first && ARGV.first[0] == '-'
      opt = ARGV.shift
      case opt
      when '-h', '--help' then usage
      when '-e', '--re-encode' then @re_encode = true
      when '--' then break
      else warn "invalid option #{opt.inspect}, ignored"
      end
    end

    @source_dir = ARGV.shift || '.'
    @target_dir = ARGV.shift || "#{@source_dir}/daisy"

    unless ARGV.empty?
      warn "extra arguments ignored: #{ARGV.map(&:inspect).join(', ')}"
    end

  end

end
end