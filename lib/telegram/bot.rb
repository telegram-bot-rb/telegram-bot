require 'telegram/bot/config_methods'

module Telegram
  extend Bot::ConfigMethods

  module Bot
    class Error < StandardError; end
    class NotFound < Error; end

    autoload :Client,             'telegram/bot/client'
    autoload :ClientStub,         'telegram/bot/client_stub'
    autoload :Middleware,         'telegram/bot/middleware'
    autoload :UpdatesController,  'telegram/bot/updates_controller'
    autoload :UpdatesPoller,      'telegram/bot/updates_poller'
  end
end

require 'telegram/bot/railtie' if defined?(Rails)
