# frozen_string_literal: true

require_relative 'lib/compare_compressors/version'

Gem::Specification.new do |s|
  s.name        = 'compare_compressors'
  s.version     = CompareCompressors::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['John Lees-Miller']
  s.email       = ['jdleesmiller@gmail.com']
  s.homepage    = 'https://github.com/jdleesmiller/compare_compressors'
  s.summary     = %(
    Compare compression algorithms (gzip, bzip2, xz, etc.) for a sample of
    documents.
  )
  s.description = %(
    Compare compression algorithms (gzip, bzip2, xz, etc.) for a sample of
    documents.
  )

  s.add_runtime_dependency 'thor', '~> 0.19.4'
  s.add_development_dependency 'gemma', '~> 5.0.0'

  s.files       = Dir.glob('{lib,bin}/**/*.rb') + %w[README.md]
  s.test_files  = Dir.glob('test/compare_compressors/*_test.rb')
  s.executables = Dir.glob('bin/*').map { |f| File.basename(f) }

  s.rdoc_options = [
    '--main',    'README.md',
    '--title',   "#{s.full_name} Documentation"
  ]
  s.extra_rdoc_files << 'README.md'
end
