require 'telegram/bot/rspec/integration'
require 'action_controller'
require 'action_dispatch'
require 'action_dispatch/testing/integration'

require 'rails'
require 'rspec/rails/adapters'
require 'rspec/rails/fixture_support'
require 'rspec/rails/example/rails_example_group'
require 'rspec/rails/example/request_example_group'

ENV['RAILS_ENV'] = 'test'
class TestApplication < Rails::Application
  config.eager_load = false
  config.log_level = :debug
  secrets[:secret_key_base] = 'test'
  secrets[:telegram] = {
    bot: 'default_token',
    bots: {
      other: {token: 'other_token'},
    },
  }
end
Rails.application.initialize!

# # Controllers
class DefaultBotController < Telegram::Bot::UpdatesController
  def start(*)
    respond_with :message, text: 'from default'
  end
end

class OtherBotController < Telegram::Bot::UpdatesController
  def start(*)
    respond_with :message, text: 'from other'
  end
end

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

      telegram_webhooks default: DefaultBotController,
                        other: OtherBotController
    end
  end
end
