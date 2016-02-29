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
          token.tr(':', '_')
        end
      end

      #   # Create routes for all Telegram.bots to use same controller:
      #   telegram_webhooks TelegramController
      #
      #   # Or pass custom bots usin any of supported config options:
      #   telegram_webhooks TelegramController,
      #                     bot,
      #                     {token: token, username: username},
      #                     other_bot_token
      #
      #   # Use different controllers for each bot:
      #   telegram_webhooks bot => TelegramChatController,
      #                     other_bot => TelegramAuctionController
      #
      #   # telegram_webhooks creates named routes. See
      #   # RoutesHelper.route_name_for_bot for more info.
      #   # You can override this options or specify others:
      #   telegram_webhooks TelegramController, as: :my_webhook
      #   telegram_webhooks bot => [TelegramChatController, as: :chat_webhook],
      #                     other_bot => [TelegramAuctionController,
      def telegram_webhooks(controllers, bots = nil, **options)
        unless controllers.is_a?(Hash)
          bots = bots ? Array.wrap(bots) : Telegram.bots.values
          controllers = Hash[bots.map { |x| [x, controllers] }]
        end
        controllers.each do |bot, controller|
          bot = Client.wrap(bot)
          controller, bot_options = controller if controller.is_a?(Array)
          params = {
            to: Middleware.new(bot, controller),
            as: RoutesHelper.route_name_for_bot(bot),
            format: false,
          }.merge!(options).merge!(bot_options || {})
          post("telegram/#{RoutesHelper.escape_token bot.token}", params)
          UpdatesPoller.add(bot, controller) if Telegram.bot_poller_mode?
        end
      end
    end
  end
end
