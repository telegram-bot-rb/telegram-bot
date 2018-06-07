module Telegram
  module Bot
    class UpdatesController
      # Allows to store context in session and treat next message according to this context.
      #
      # It provides `save_context` method to store method name
      # to be used as action for next update:
      #
      #     def set_location!(*)
      #       save_context(:set_location_from_message)
      #       respond_with :message, text: 'Where are you?'
      #     end
      #
      #     def set_location_from_messge(city = nil, *)
      #       # update
      #     end
      #
      #     # OR
      #     # This will support both `/set_location city_name`, and `/set_location`
      #     # with subsequent refinement.
      #     def set_location!(city = nil, *)
      #       if city
      #         # update
      #       else
      #         save_context(:set_location!)
      #         respond_with :message, text: 'Where are you?'
      #       end
      #     end
      module MessageContext
        extend ActiveSupport::Concern

        include Session

        # Action to clear context.
        def cancel!
          # Context is already cleared in action_for_message
        end

        private

        # Controller may have multiple sessions, let it be possible
        # to select session for message context.
        def message_context_session
          session
        end

        # Fetches context and finds handler for it. If message has new command,
        # it has higher priority than contextual action.
        def action_for_message
          val = message_context_session.delete(:context)
          context = val && val.to_s
          super || context && begin
            args = payload['text'].try!(:split) || []
            action = action_for_message_context(context)
            [[action, type: :message_context, context: context], args]
          end
        end

        # Save context for the next request.
        def save_context(context)
          message_context_session[:context] = context
        end

        # Returns action name for message context. By default it's the same as context name.
        # Raises AbstractController::ActionNotFound if action is not available.
        # This differs from other cases where invalid actions are silently ignored,
        # because message context is controlled by developer, and users are not able
        # to construct update to run any specific context.
        def action_for_message_context(context)
          action = context.to_s
          return action if action_method?(action)
          raise AbstractController::ActionNotFound,
            "The context action '#{action}' is not found in #{self.class.name}"
        end
      end
    end
  end
end
