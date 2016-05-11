module Telegram
  module Bot
    class UpdatesController
      # Allows to store context in session and treat next message according to this context.
      module MessageContext
        extend ActiveSupport::Concern

        include Session

        included do
          # As we use before_action context is cleared anyway,
          # no matter we used it or not.
          before_action :fetch_context
          singleton_class.send :attr_reader, :context_handlers, :context_to_action
          @context_handlers = {}
        end

        module ClassMethods
          # Registers handler for context.
          #
          #     context_handler :rename do |message|
          #       resource.update!(name: message['text'])
          #     end
          #
          #     # To run other action with all the callbacks:
          #     context_handler :rename do |message|
          #       process(:rename, *m['text'].try!(:split)) # Message can be without text
          #     end
          #
          #     # Or just
          #     context_handler :rename, :your_action_to_call
          #     context_handler :rename # to call :rename
          #
          #     # For messages without context use this instead of `message` method:
          #     context_handler do |message|
          #     end
          #
          def context_handler(context = nil, action = nil, &block)
            context &&= context.to_sym
            context_handlers[context] = block || action || context
          end

          # Use it to use context value as action name for all contexts
          # which miss handlers.
          # For security reasons it supports only action methods and will
          # raise AbstractController::ActionNotFound if context is invalid.
          def context_to_action!
            @context_to_action = true
          end
        end

        # Finds handler for current context and processes message with it.
        def message(message)
          handler = handler_for_context
          return unless handler
          if handler.respond_to?(:call)
            instance_exec(message, &handler)
          else
            process(handler, *message['text'].try!(:split))
          end
        end

        # Action to clear context.
        def cancel
          # Context is already cleared in before_action
        end

        private

        # Context is read from the session to treat messages
        # according to previous request.
        attr_reader :context

        # Fetches and removes context from session.
        def fetch_context
          val = session.delete(:context)
          @context = val && val.to_sym
          true # TODO: remove in Rails 5.0
        end

        # Save context for the next request.
        def save_context(context)
          session[:context] = context
        end

        def handler_for_context
          self.class.context_handlers[context] || self.class.context_to_action && begin
            action_name = context.to_s
            unless action_method?(action_name)
              raise AbstractController::ActionNotFound,
                "The action '#{action_name}' could not be set from context " \
                "for #{self.class.name}. " \
                'context_to_action! supports only action methods for security reasons. ' \
                'If you need to call this action use context_handler for it.'
            end
            action_name
          end
        end
      end
    end
  end
end
