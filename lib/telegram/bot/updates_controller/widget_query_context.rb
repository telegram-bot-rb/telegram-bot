# frozen_string_literal: true

module Telegram
  module Bot
    class UpdatesController
      # Use separate actions for different queries from widgets.
      # It works the same way as CallbackQueryContext: add `%{context}:` prefix
      # to data in `TelegramWidget.request('context:data')`.
      module WidgetQueryContext
        protected

        # Uses #context_from_widget_query as context name.
        # If context is present checks if `%context%_widget_query` is valid
        # action method and returns it if so. Context is stripped from data
        # in this case. Otherwise returns `super`.
        #
        # It wont raise ActionNotFound, because `data` param is controlled by client.
        def action_for_widget_query
          action_for_widget_query_context || super
        end

        # Same as #action_for_widget_query, but action name is
        # `%context%_shared_widget_query`.
        def action_for_shared_widget_query
          action_for_widget_query_context || super
        end

        def action_for_widget_query_context
          context, new_data = context_from_widget_query
          return unless context
          action_name = "#{context}_#{payload_type}"
          # `shared:data` in widget_query must not get to shared_widget_query action.
          return if PAYLOAD_TYPES.include?(action_name) || !action_method?(action_name)
          [[action_name, {type: :widget_query_context, context: context}], [new_data]]
        end

        def context_from_widget_query
          data = payload['data']
          return unless data
          parts = data.split(':', 2)
          parts if parts.size > 1
        end
      end
    end
  end
end
