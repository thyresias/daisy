# encoding: utf-8

h = Object.new  # helper object

def h.doc_files
  %w(README.md HISTORY.md)
end

def h.lib_files
  Dir['lib/**/*'].reject { |f| File.directory?(f) }
end

def h.bin_files
  Dir['bin/*']
end

def h.test_files
  Dir['test/**/*'].reject { |f| File.directory?(f) }
end

def h.version
  line = File.read('lib/daisy/version.rb').lines.grep(/VERSION/).first
  line[/VERSION\s*=\s*(['"])(.+)\1/, 2]
end

def h.runtime_deps
  %w(
    psych    ~> 5.1
  )
end

Gem::Specification.new do |s|
  s.name = 'daisy-audio'
  s.summary = "DAISY audio format support."
  s.description = <<~TEXT
    Creates DAISY-compliant files.
  TEXT
  s.license = 'MIT'

  s.version = h.version

  s.author = 'Thierry Lambert'
  s.email = 'thyresias@gmail.com'
  s.homepage = 'https://github.com/thyresias/daisy'

  s.files = ['Rakefile'] + h.doc_files + h.lib_files + h.bin_files + h.test_files

  s.bindir = 'bin'
  s.executables = h.bin_files.map { |f| File.basename(f) }

  s.extra_rdoc_files = h.doc_files
  s.rdoc_options <<
    '--title' << 'DAISY Audio' <<
    '--main' << h.doc_files.first

  h.runtime_deps.each_slice(3) do |name, op, version|
    s.add_runtime_dependency name, ["#{op}#{version}"]
  end
end
