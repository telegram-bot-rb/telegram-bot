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
          chat_id = chat && chat['id'] or raise 'Can not respond_with when chat is not present'
          bot.public_send("send_#{type}", params.merge(chat_id: chat_id))
        end

        # Same as respond_with but also sets `reply_to_message_id`.
        def reply_with(type, params)
          payload = self.payload
          message_id = payload && payload['message_id']
          params = params.merge(reply_to_message_id: message_id) if message_id
          respond_with(type, params)
        end

        # Same as respond_with, but for inline queries.
        def answer_inline_query(results, params = {})
          params = params.merge(
            inline_query_id: payload['id'],
            results: results,
          )
          bot.answer_inline_query(params)
        end

        # Same as respond_with, but for callback queries.
        def answer_callback_query(text, params = {})
          params = params.merge(
            callback_query_id: payload['id'],
            text: text,
          )
          bot.answer_callback_query(params)
        end

        # Same as respond_with, but for pre checkout queries.
        def answer_pre_checkout_query(ok, params = {})
          params = params.merge(
            pre_checkout_query_id: payload['id'],
            ok: ok,
          )
          bot.answer_pre_checkout_query(params)
        end

        def answer_shipping_query(ok, params = {})
          params = params.merge(
            shipping_query_id: payload['id'],
            ok: ok,
          )
          bot.answer_shipping_query(params)
        end

        # Edit message from callback query.
        def edit_message(type, params = {})
          params =
            if message_id = payload['inline_message_id'] # rubocop:disable AssignmentInCondition
              params.merge(inline_message_id: message_id)
            elsif message = payload['message'] # rubocop:disable AssignmentInCondition
              params.merge(chat_id: message['chat']['id'], message_id: message['message_id'])
            else
              raise 'Can not edit message without `inline_message_id` or `message`'
            end
          bot.public_send("edit_message_#{type}", params)
        end
      end
    end
  end
end
