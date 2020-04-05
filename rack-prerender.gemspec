# coding: utf-8

require File.join(__dir__, 'lib', 'rack', 'prerender', 'version')

Gem::Specification.new do |s|
  s.platform      = Gem::Platform::RUBY
  s.name          = 'rack-prerender'
  s.version       = Rack::Prerender::VERSION
  s.license       = 'MIT'

  s.summary       = 'Prerender your javascript rendered application on the fly when search engines crawl'
  s.description   = 'Rack middleware to prerender your javascript heavy pages on the fly (fork of prerender_rails).'

  s.authors       = ['Todd Hooper', 'Janosch Müller']
  s.email         = ['todd@prerender.io', 'janosch84@gmail.com']
  s.homepage      = 'https://github.com/jaynetics/rack-prerender'

  s.files         = Dir[File.join('lib', '**', '*.rb')]

  s.required_ruby_version = '>= 2.4.0'

  s.add_dependency 'rack'

  s.add_development_dependency 'activejob'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'webmock'
end
