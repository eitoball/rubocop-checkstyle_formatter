# frozen_string_literal: true

require 'English'
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = 'rubocop-checkstyle_formatter'
  gem.version       = '0.5.0'
  gem.authors       = ['Eito Katagiri']
  gem.email         = ['eitoball@gmail.com']
  gem.description   = 'A formatter for rubocop that outputs in checkstyle format'
  gem.summary       = 'A formatter for rubocop that outputs in checkstyle format'
  gem.homepage      = 'https://github.com/eitoball/rubocop-checkstyle_formatter'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'rubocop', '>= 1.20.0'
  gem.add_development_dependency 'appraisal', '~> 2.4.1'
  gem.add_development_dependency 'bundler', '>= 2.2.10'
  gem.add_development_dependency 'rake', '>= 12.3.3'
  gem.add_development_dependency 'rspec', '~> 3.5.0'
end
