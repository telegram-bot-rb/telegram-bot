require 'telegram/bot/config_methods'

module Telegram
  extend Bot::ConfigMethods

  module Bot
    class Error < StandardError; end

    # Raised for valid telegram response with 403 status code.
    class Forbidden < Error; end

    # Raised for valid telegram response with 404 status code.
    class NotFound < Error; end

    module_function

    def deprecation_0_15
      @deprecation ||= begin
        require 'active_support/deprecation'
        ActiveSupport::Deprecation.new('0.15', 'Telegram::Bot')
      end
    end

    autoload :Async,              'telegram/bot/async'
    autoload :Client,             'telegram/bot/client'
    autoload :ClientStub,         'telegram/bot/client_stub'
    autoload :DebugClient,        'telegram/bot/debug_client'
    autoload :Initializers,       'telegram/bot/initializers'
    autoload :Middleware,         'telegram/bot/middleware'
    autoload :RSpec,              'telegram/bot/rspec'
    autoload :UpdatesController,  'telegram/bot/updates_controller'
    autoload :UpdatesPoller,      'telegram/bot/updates_poller'
  end
end

require 'telegram/bot/railtie' if defined?(Rails)
