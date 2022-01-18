# frozen_string_literal: true

require_relative 'lib/msidp/endpoint/version'

Gem::Specification.new do |spec|
  spec.name = 'msidp-endpoint'
  spec.version = MSIDP::Endpoint::VERSION
  spec.authors = ['SHIMAYOSHI, Takao']
  spec.email = ['simayosi@cc.kyushu-u.ac.jp']

  spec.summary = 'MSIDP::Endpoint'
  spec.description =
    'Simple class library for Microsoft Identity Platform endpoints.'
  spec.homepage = 'https://github.com/simayosi/rb-msidp-endpoint'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['documentation_uri'] =
    'https://rubydoc.info/gems/msidp-endpoint'

  spec.files = Dir['lib/**/*', 'sig/**/*', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']
end
