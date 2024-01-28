$VERBOSE = true
require_relative 'lib/daisy'

desc 'build & install gem'
task 'gem' do
  system 'gem build daisy.gemspec'
  system 'gem install daisy-audio --local'
end

desc 'create RDoc documentation'
task 'rdoc' do
  require 'rdoc/rdoc'
  FileUtils.rm_r 'doc/rdoc' if File.directory?('doc/rdoc')
  args = %w(--force-update --force-output --all)  # --hyperlink-all
  args << '-f' << 'babel'
  args << '-c' << 'utf-8'
  args << '--see-standard-ancestors'
  args << '-o' << 'doc/rdoc'
  args << '-t' << 'DAISY Audio'
  args << '--main' << 'README.md'
  args.concat %w(README.md HISTORY.md lib)
  RDoc::RDoc.new.document(args)
end

desc 'run all tests'
task 'test' do
  # TODO
end
