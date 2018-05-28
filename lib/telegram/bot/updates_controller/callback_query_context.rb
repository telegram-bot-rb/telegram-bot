module Telegram
  module Bot
    class UpdatesController
      # Use separate actions for different callback queries.
      # It doesn't require session support. Simply add `%{context}:` prefix to data.
      module CallbackQueryContext
        protected

        # Uses #context_from_callback_query as context name.
        # If context is present checks if `%context%_callback_query` is valid
        # action method and returns it if so. Context is stripped from data
        # in this case. Otherwise returns `super`.
        #
        # It wont raise ActionNotFound as MessageContext does,
        # because `data` param is controlled by client.
        def action_for_callback_query
          context, new_data = context_from_callback_query
          if context
            action_name = "#{context}_callback_query"
            if action_method?(action_name)
              action_options = {type: :callback_query_context, context: context}
              return [[action_name, action_options], [new_data]]
            end
          end
          super
        end

        def context_from_callback_query
          data = payload['data']
          return unless data
          parts = data.split(':', 2)
          parts if parts.size > 1
        end
      end
    end
  end
end
