# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'httpi/adapter/openssl_gost/version'

Gem::Specification.new do |spec|
  spec.name          = 'httpi-adapter-openssl_gost'
  spec.version       = HTTPI::Adapter::OpensslGost::VERSION
  spec.authors       = ['Andrey Novikov']
  spec.email         = ['envek@envek.name']
  spec.summary       = 'HTTPI adapter for accessing HTTPS servers with GOST algorithms and certificates'
  spec.description   = 'It uses OpenSSL `s_client` command to securely connect with server that requires usage of GOST algorithms and client certificates.'
  spec.homepage      = 'https://github.com/Envek/httpi-adapter-openssl_gost'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.requirements << 'OpenSSL 1.0.0 and newer with GOST engine installed, enabled, and configured.'
  spec.add_dependency 'httpi', '~> 2.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10'
end
