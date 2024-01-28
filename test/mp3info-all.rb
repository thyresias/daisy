require 'pp'

files = Dir['**/*.mp3']

# mp3info

puts "\n=== Mp3Info"

def without_warning
  old, $-w = $-w, nil
  begin
    result = yield
  ensure
    $-w = old
  end

  result
end

without_warning { require 'mp3info' }

files.each do |path|
  puts "--- #{path}"
  Mp3Info.open(path) do |i|
    pp i
  end
end
