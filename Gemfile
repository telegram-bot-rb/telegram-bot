source 'https://rubygems.org'
gemspec

group :development do
  case ENV['RAILS']
  when '5_1'
    gem 'railties', '5.1.0'
    gem 'actionpack', '5.1.0'
  when '5'
    gem 'railties', '5.0.2'
    gem 'actionpack', '5.0.2'
  when '4'
    gem 'railties', '~> 4.2'
    gem 'actionpack', '~> 4.2'
  else
    gem 'railties'
    gem 'actionpack'
  end

  gem 'sdoc', '~> 0.4.1'
  gem 'pry', '~> 0.10.1'
  gem 'pry-byebug', '~> 3.2.0'

  gem 'telegram-bot-types', '~> 0.3.0'

  gem 'rspec', '~> 3.5.0'
  gem 'rspec-its', '~> 1.1.0'
  gem 'rspec-rails', '~> 3.5.0'

  gem 'rubocop', '~> 0.37.0'

  gem 'coveralls', '~> 0.8.2', require: false
end
