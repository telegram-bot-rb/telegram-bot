module Telegram
  module Bot
    class UpdatesController
      module ReplyHelpers
        # Helper to call bot's `send_#{type}` method with already set `chat_id`:
        #
        #     respond_with :message, text: 'Hello!'
        #     respond_with :message, text: '__Hello!__', parse_mode: :Markdown
        #     respond_with :photo, photo: File.open(photo_to_send), caption: "It's incredible!"
        def respond_with(type, params)
          chat = self.chat
          chat_id = chat && (update.nil?? chat : chat['id']) or raise 'Can not respond_with when chat is not present'
          bot.public_send("send_#{type}", params.merge(chat_id: chat_id))
        end

        # Same as respond_with but also sets `reply_to_message_id`.
        def reply_with(type, params)
          payload = self.payload
          message_id = payload && payload['message_id']
          params = params.merge(reply_to_message_id: message_id) if message_id
          respond_with(type, params)
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
