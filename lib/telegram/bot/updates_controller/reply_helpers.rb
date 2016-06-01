module Telegram
  module Bot
    class UpdatesController
      module ReplyHelpers
        # Helper to call bot's `send_#{type}` method with already set `chat_id` and
        # `reply_to_message_id`:
        #
        #     reply_with :message, text: 'Hello!'
        #     reply_with :message, text: '__Hello!__', parse_mode: :Markdown
        #     reply_with :photo, photo: File.open(photo_to_send), caption: "It's incredible!"
        def reply_with(type, params)
          method = "send_#{type}"
          chat = self.chat
          payload = self.payload
          params = params.merge(
            chat_id: (chat && chat['id'] or raise 'Can not reply_with when chat is not present'),
            reply_to_message_id: payload && payload['message_id'],
          )
          bot.public_send(method, params)
        end

        # Same as reply_with, but for inline queries.
        def answer_inline_query(results, params = {})
          params = params.merge(
            inline_query_id: payload['id'],
            results: results,
          )
          bot.answer_inline_query(params)
        end

        # Same as reply_with, but for callback queries.
        def answer_callback_query(text, params = {})
          params = params.merge(
            callback_query_id: payload['id'],
            text: text,
          )
          bot.answer_callback_query(params)
        end
      end
    end
  end
end
