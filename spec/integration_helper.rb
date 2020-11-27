require 'telegram/bot/rspec/integration/rails'
require 'action_controller'
require 'action_dispatch'

require 'rails'
require 'telegram/bot/railtie'
require 'rspec/rails/adapters'
require 'rspec/rails/fixture_support'
require 'rspec/rails/example/rails_example_group'
require 'rspec/rails/example/request_example_group'

ENV['RAILS_ENV'] = 'test'
class TestApplication < Rails::Application
  config.eager_load = false
  config.log_level = :debug
  config.action_dispatch.show_exceptions = false
  routes.default_url_options = {host: 'test.rpsec'}

  telegram_config = {
    bot: 'default_token',
    bots: {
      other: {token: 'other_token'},
      named: {token: 'named_token', username: 'TestBot'},
    },
  }

  if respond_to?(:credentials)
    credentials.config[:telegram] = telegram_config
  else
    secrets[:secret_key_base] = 'test'
    secrets[:telegram] = telegram_config
  end
end
Rails.application.initialize!

# # Controllers
%w[default other named].each do |bot_name|
  controller = Class.new(Telegram::Bot::UpdatesController) do
    define_method :start! do |*|
      respond_with :message, text: "from #{bot_name}"
    end
  end
  Object.const_set("#{bot_name}_bot_controller".camelize, controller)
end

[DefaultBotController, OtherBotController].each do |klass|
  klass.class_eval do
    use_session!

    define_method :load_session! do |*|
      session[:test]
    end
  end
end

DefaultBotController.session_store = :memory_store

RSpec.configure do |config|
  config.include RSpec::Rails::RequestExampleGroup, type: :request

  config.around type: :request do |ex|
    begin
      Telegram.reset_bots
      Telegram::Bot::ClientStub.stub_all!
      ex.run
    ensure
      Telegram.reset_bots
      Telegram::Bot::ClientStub.stub_all!(false)
    end
  end

  config.before type: :request do
    # Redefine routes before every example, so it does not depent on order.
    Rails.application.routes.draw do
      require 'telegram/bot/routes_helper'
      extend Telegram::Bot::RoutesHelper

      telegram_webhook DefaultBotController, :default
      telegram_webhook OtherBotController, :other
      telegram_webhook NamedBotController, :named
    end
  end
end
