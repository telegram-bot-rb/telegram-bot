require 'active_support/rescuable'

module Telegram
  module Bot
    class UpdatesController
      module Rescue
        extend ActiveSupport::Concern
        include ActiveSupport::Rescuable

        private

        def process_action(*)
          super
        rescue Exception => exception # rubocop:disable RescueException
          rescue_with_handler(exception) || raise
        end
      end
    end
  end
end
