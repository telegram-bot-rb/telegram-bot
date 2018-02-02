require 'telegram/bot'
require 'active_support/core_ext/array/wrap'

module Telegram
  module Bot
    module RoutesHelper
      class << self
        # Returns route name for given bot. Result depends on `Telegram.bots`.
        # When there is single bot it returns 'telegram_webhook'.
        # When there are it will use bot's key in the `Telegram.bots` as prefix
        # (eg. `chat_telegram_webhook`).
        def route_name_for_bot(bot)
          bots = Telegram.bots
          if bots.size != 1
            name = bots.invert[bot]
            name && "#{name}_telegram_webhook"
          end || 'telegram_webhook'
        end

        # Replaces colon with underscore so rails don't treat it as
        # route parameter.
        def escape_token(token)
          token && token.tr(':', '_')
        end
      end

      #   # Create routes for all Telegram.bots to use same controller:
      #   telegram_webhooks TelegramController
      #
      #   # Or pass custom bots usin any of supported config options:
      #   telegram_webhooks TelegramController, [
      #     bot,
      #     {token: token, username: username},
      #     other_bot_token,
      #   ]
      def telegram_webhooks(controllers, bots = nil, **options)
        Bot.deprecation_0_14.deprecation_warning(:telegram_webhooks, <<-TXT.strip_heredoc)
          It brings unnecessary complexity and encourages writeng less readable code.
          Please use telegram_webhook method instead.
          It's signature `telegram_webhook(controller, bot = :default, **options)`.
          Multiple-bot environments now requires calling this method in a loop
          or using statement for each bot.
        TXT
        unless controllers.is_a?(Hash)
          bots = bots ? Array.wrap(bots) : Telegram.bots.values
          controllers = Hash[bots.map { |x| [x, controllers] }]
        end
        controllers.each do |bot, controller|
          controller, bot_options = controller if controller.is_a?(Array)
          telegram_webhook(controller, bot, options.merge(bot_options || {}))
        end
      end

      # Define route which processes requests using given controller and bot.
      #
      #   telegram_webhook TelegramController, bot
      #
      #   telegram_webhook TelegramController
      #   # same as:
      #   telegram_webhook TelegramController, :default
      #
      #   # pass additional options
      #   telegram_webhook TelegramController, :default, as: :custom_route_name
      def telegram_webhook(controller, bot = :default, **options)
        bot = Client.wrap(bot)
        params = {
          to: Middleware.new(bot, controller),
          as: RoutesHelper.route_name_for_bot(bot),
          format: false,
        }.merge!(options)
        post("telegram/#{RoutesHelper.escape_token bot.token}", params)
        UpdatesPoller.add(bot, controller) if Telegram.bot_poller_mode?
      end
    end
  end
end
