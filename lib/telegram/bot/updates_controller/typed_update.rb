module Telegram
  module Bot
    class UpdatesController
      # Include this module to type cast update to Virtus model
      # using `telegram-bot-types` gem (install this gem first).
      module TypedUpdate
        def initialize(bot = nil, update = nil, webhook_request = nil)
          update = Types::Update.new(update) if update && !update.is_a?(Types::Update)
          super
        end
      end
    end
  end
end
