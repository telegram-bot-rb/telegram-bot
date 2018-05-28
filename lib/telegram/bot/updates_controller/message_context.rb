module Telegram
  module Bot
    class UpdatesController
      # Allows to store context in session and treat next message according to this context.
      module MessageContext
        extend ActiveSupport::Concern

        include Session

        module ClassMethods
          def context_handlers
            @_context_handlers ||= {}
          end

          # Registers handler for context.
          #
          #     context_handler :rename do |*|
          #       resource.update!(name: payload['text'])
          #     end
          #
          #     # To run other action with all the callbacks:
          #     context_handler :rename do |*words|
          #       process(:rename, *words)
          #     end
          #
          #     # Or just
          #     context_handler :rename, :your_action_to_call
          #     context_handler :rename # to call :rename
          #
          def context_handler(context = nil, action = nil, &block)
            context &&= context.to_sym
            if block
              action = "_context_handler_#{context}"
              define_method(action, &block)
            end
            context_handlers[context] = action || context
          end

          attr_reader :context_to_action

          # Use it to use context value as action name for all contexts
          # which miss handlers.
          # For security reasons it supports only action methods and will
          # raise AbstractController::ActionNotFound if context is invalid.
          def context_to_action!
            @context_to_action = true
          end
        end

        # Action to clear context.
        def cancel!
          # Context is already cleared in action_for_message
        end

        private

        # Context is read from the session to treat messages
        # according to previous request.
        attr_reader :context

        # Controller may have multiple sessions, let it be possible
        # to select session for message context.
        def message_context_session
          session
        end

        # Fetches context and finds handler for it. If message has new command,
        # it has higher priority than contextual action.
        def action_for_message
          val = message_context_session.delete(:context)
          @context = val && val.to_sym
          super || context && begin
            handler = handler_for_context
            if handler
              action_options = {type: :message_context, context: context}
              [[handler, action_options], payload['text'].try!(:split) || []]
            end
          end
        end

        # Save context for the next request.
        def save_context(context)
          message_context_session[:context] = context
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
