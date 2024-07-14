require 'pp'

def without_warning
  old, $-w = $-w, nil
  begin
    result = yield
  ensure
    $-w = old
  end

  result
end

files = Dir['**/*.mp3']

File.open(__FILE__.sub('.rb', '.out'), 'wb') do |io|

  # mp3info

  io.puts "\n=== Mp3Info"

  without_warning { require 'mp3info' }

  files.each do |path|
    io.puts "\n--- #{path}"
    Mp3Info.open(path) do |i|
      PP.pp(i, io, 100)
    end
  end
end
