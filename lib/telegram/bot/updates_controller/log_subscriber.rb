# frozen_string_literal: true

require 'active_support/log_subscriber'
require 'active_support/parameter_filter'

module Telegram
  module Bot
    class UpdatesController
      class LogSubscriber < ActiveSupport::LogSubscriber
        # Payload keys to obfuscate before logging an update, e.g. to keep users'
        # message text out of the logs. Assign own list (or `[]` to disable) with:
        #
        #   Telegram::Bot::UpdatesController::LogSubscriber.filtered_parameters = [...]
        mattr_accessor :filtered_parameters, instance_writer: false
        self.filtered_parameters = %i[text]

        def start_processing(event)
          info do
            payload = event.payload
            update = filter_update(payload[:update])
            "Processing by #{payload[:controller]}##{payload[:action]}\n" \
              "  Update: #{update.to_json}"
          end
        end

        def process_action(event)
          info do
            payload   = event.payload
            additions = UpdatesController.log_process_action(payload)
            message = "Completed in #{event.duration.round}ms"
            message += " (#{additions.join(' | ')})" if additions.present?
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

        private

        def filter_update(update)
          hash = update.respond_to?(:to_h) ? update.to_h : update
          parameter_filter.filter(hash)
        end

        def parameter_filter
          ActiveSupport::ParameterFilter.new(filtered_parameters)
        end
      end
    end
  end
end
