require 'active_support/log_subscriber'

module Telegram
  module Bot
    class UpdatesController
      class LogSubscriber < ActiveSupport::LogSubscriber
        def start_processing(event)
          info do
            payload = event.payload
            "Processing by #{payload[:controller]}##{payload[:action]}\n" \
            "  Update: #{payload[:update].to_json}"
          end
        end

        def process_action(event)
          info do
            payload   = event.payload
            additions = UpdatesController.log_process_action(payload)
            message = "Completed in #{event.duration.round}ms"
            message << " (#{additions.join(' | ')})" if additions.present?
            message
          end
        end

        def respond_with(event)
          info { "Responded with #{event.payload[:type]}" }
        end

        def halted_callback(event)
          info { "Filter chain halted at #{event.payload[:filter].inspect}" }
        end

        delegate :logger, to: UpdatesController
        attach_to 'updates_controller.bot.telegram'
      end
    end
  end
end
