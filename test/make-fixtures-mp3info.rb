require 'fileutils'
require 'yaml'
require 'zlib'

FIXTURES = YAML::load_file("fixtures-mp3info.yml")
OUTDIR = 'fixtures-mp3info'
FileUtils.mkpath OUTDIR unless File.directory?(OUTDIR)

def create_fixture(fixture_key, zlibed = true)
  # Command to create a gzip'ed dummy MP3
  # $ dd if=/dev/zero bs=1024 count=15 | \
  #   lame --quiet --preset cbr 128 -r -s 44.1 --bitwidth 16 - - | \
  #   ruby -rbase64 -rzlib -ryaml -e 'print(Zlib::Deflate.deflate($stdin.read)'
  # vbr:
  # $ dd if=/dev/zero of=#{tempfile.path} bs=1024 count=30000 |
  #     system("lame -h -v -b 112 -r -s 44.1 --bitwidth 16 - /tmp/vbr.mp3
  #
  # this will generate a #{mp3_length} sec mp3 file (44100hz*16bit*2channels) = 60/4 = 15
  # system("dd if=/dev/urandom bs=44100 count=#{mp3_length*4}  2>/dev/null | \
  #        lame -v -m s --vbr-new --preset 128 -r -s 44.1 --bitwidth 16 - -  > #{TEMP_FILE} 2>/dev/null")
  content = FIXTURES[fixture_key]
  if zlibed
    content = Zlib::Inflate.inflate(content)
  end

  outfile = "#{OUTDIR}/#{fixture_key}.mp3"
  File.write outfile, content, mode: 'wb'
end

create_fixture "empty_mp3"
create_fixture "vbr"
create_fixture "2_2_tagged"
create_fixture "2_2_tagged"
create_fixture "audio_content_fixture", false
create_fixture "small_vbr_mp3"
create_fixture "22k", false
create_fixture "vbr"
create_fixture "utf16_no_bom"
