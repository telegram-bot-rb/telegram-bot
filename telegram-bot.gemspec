lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'telegram/bot/version'

Gem::Specification.new do |spec|
  spec.name          = 'telegram-bot'
  spec.version       = Telegram::Bot::VERSION
  spec.authors       = ['Max Melentiev']
  spec.email         = ['melentievm@gmail.com']

  spec.summary       = 'Library for building Telegram Bots with Rails integration'
  spec.homepage      = 'https://github.com/telegram-bot-rb/telegram-bot'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4'

  spec.add_dependency 'actionpack', '>= 4.0', '< 6.2'
  spec.add_dependency 'activesupport', '>= 4.0', '< 6.2'
  spec.add_dependency 'httpclient', '~> 2.7'

  spec.add_development_dependency 'bundler', '> 1.16'
  spec.add_development_dependency 'rake', '~> 13.0'
end
