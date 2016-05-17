module Telegram
  module Bot
    class UpdatesController
      # Use separate actions for different callback queries.
      # It doesn't require session support. Simply add `%{context}:` prefix to data.
      module CallbackQueyContext
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
          # binding.pry
          if context
            action_name = "#{context}_callback_query"
            [false, action_name, [new_data]] if action_method?(action_name)
          end || super
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
