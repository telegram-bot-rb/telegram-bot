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
      #
      # It's enabled by default in Rails dev environment and `rake telegram:bot:poller`
      # task. Use `BOT_POLLER_MODE=true` envvar to set it manually.
      def bot_poller_mode?
        return @bot_poller_mode if defined?(@bot_poller_mode)
        @bot_poller_mode = ENV.fetch('BOT_POLLER_MODE') do
          Rails.env.development? if defined?(Rails.env)
        end
      end

      # Hash of bots made with bots_config.
      def bots
        @bots ||= bots_config.each_with_object({}) do |(id, config), h|
          h[id] = Client.wrap(config, id: id)
        end
      end

      # Default bot.
      def bot
        @bot ||= bots[:default]
      end

      # Hash of botan clients made from #bots.
      def botans
        @botans ||= bots.transform_values(&:botan)
      end

      # Returns config for .bots method. By default uses `telegram['bots']` section
      # from `secrets.yml` merging `telegram['bot']` at `:default` key.
      #
      # Can be overwritten with .bots_config=
      def bots_config
        @bots_config ||=
          if defined?(Rails.application)
            telegram_config = Rails.application.secrets[:telegram] || {}
            (telegram_config['bots'] || {}).symbolize_keys.tap do |config|
              default = telegram_config['bot']
              config[:default] = default if default
            end
          else
            {}
          end
      end

      # Resets all cached bots and their configs.
      def reset_bots
        @bots = nil
        @bot = nil
        @bots_config = nil
        @botans = nil
      end
    end
  end
end
