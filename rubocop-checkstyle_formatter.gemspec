# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = 'rubocop-checkstyle_formatter'
  gem.version       = '0.0.1'
  gem.authors       = ['Eito Katagiri']
  gem.email         = ['eitoball@gmail.com']
  gem.description   = %q{A formatter for rubocop that outputs in checkstyle format}
  gem.summary       = %q{A formatter for rubocop that outputs in checkstyle format}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'rubocop', '>= 0.9.0'
end
