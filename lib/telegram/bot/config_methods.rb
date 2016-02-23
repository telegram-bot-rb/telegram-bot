require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/transform_values'

module Telegram
  module Bot
    module ConfigMethods
      # Overwrite config.
      attr_writer :bots_config

      # Keep this setting here, so we can avoid loading Bot::UpdatesPoller
      # when polling is disabled.
      attr_writer :bot_poller_mode

      # It just tells routes helpers whether to add routed bots to
      # Bot::UpdatesPoller, so their config will be available by bot key in
      # Bot::UpdatesPoller.start.
      def bot_poller_mode?
        return @bot_poller_mode if defined?(@bot_poller_mode)
        Rails.env.development? if defined?(Rails)
      end

      # Hash of bots made with bots_config.
      def bots
        @bots ||= bots_config.transform_values(&Client.method(:wrap))
      end

      # Default bot.
      def bot
        @bot ||= bots[:default]
      end

      # Returns config for .bots method. By default uses `telegram['bots']` section
      # from `secrets.yml` merging `telegram['bot']` at `:default` key.
      #
      # Can be overwritten with .bots_config=
      def bots_config
        return @bots_config if @bots_config
        telegram_config = Rails.application.secrets[:telegram]
        (telegram_config['bots'] || {}).symbolize_keys.tap do |config|
          default = telegram_config['bot']
          config[:default] = default if default
        end
      end
    end
  end
end
