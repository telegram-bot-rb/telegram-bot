module Telegram
  module Bot
    class UpdatesController
      # Most methods are taken from ActionController::Instrumentation,
      # some are slightly modified.
      module Instrumentation
        extend ActiveSupport::Concern

        included do
          config_accessor :logger
        end

        class << self
          def instrument(action, *args, &block)
            ActiveSupport::Notifications.instrument(
              "#{action}.updates_controller.bot.telegram",
              *args,
              &block
            )
          end
        end

        def process_action(*args)
          raw_payload = {
            controller: self.class.name,
            action:     action_name,
            update:     update,
          }
          Instrumentation.instrument(:start_processing, raw_payload.dup)
          Instrumentation.instrument(:process_action, raw_payload) do |payload|
            begin
              super
            ensure
              append_info_to_payload(payload)
            end
          end
        end

        def respond_with(type, *)
          Instrumentation.instrument(:respond_with, type: type) { super }
        end

        %i[answer_callback_query answer_inline_query].each do |type|
          define_method(type) do |*args|
            Instrumentation.instrument(:respond_with, type: type) { super(*args) }
          end
        end

        private

        # A hook invoked every time a before callback is halted.
        def halted_callback_hook(filter)
          Instrumentation.instrument(:halted_callback, filter: filter)
        end

        # A hook which allows you to clean up any time taken into account in
        # views wrongly, like database querying time.
        #
        #   def cleanup_view_runtime
        #     super - time_taken_in_something_expensive
        #   end
        #
        # :api: plugin
        def cleanup_view_runtime #:nodoc:
          yield
        end

        # Every time after an action is processed, this method is invoked
        # with the payload, so you can add more information.
        # :api: plugin
        def append_info_to_payload(_payload) #:nodoc:
        end

        module ClassMethods
          # A hook which allows other frameworks to log what happened during
          # controller process action. This method should return an array
          # with the messages to be added.
          # :api: plugin
          def log_process_action(_payload) #:nodoc:
            []
          end
        end
      end
    end
  end
end
