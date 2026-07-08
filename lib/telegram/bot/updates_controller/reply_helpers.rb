# frozen_string_literal: true

module Telegram
  module Bot
    class UpdatesController
      module ReplyHelpers
        # Helper to call bot's `send_#{type}` method with already set `chat_id`:
        #
        #     respond_with :message, text: 'Hello!'
        #     respond_with :message, text: '__Hello!__', parse_mode: :Markdown
        #     respond_with :photo, photo: File.open(photo_to_send), caption: "It's incredible!"
        #
        # Pass `via_webhook: true` to answer directly in the webhook response
        # instead of making a separate API call (see `#render_webhook_response`).
        # It's ignored (and a regular API call is made) when not running in
        # webhook mode, or when this update already claimed the webhook response.
        def respond_with(type, params)
          params, via_webhook = extract_via_webhook(params)
          chat = self.chat
          chat_id = chat && chat['id'] or raise 'Can not respond_with when chat is not present'
          full_params = params.merge(chat_id: chat_id)
          if via_webhook && render_webhook_response("send_#{type}", full_params)
            return webhook_response
          end
          bot.public_send("send_#{type}", full_params)
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
          params, via_webhook = extract_via_webhook(params)
          full_params = params.merge(
            inline_query_id: payload['id'],
            results: results,
          )
          if via_webhook && render_webhook_response(:answer_inline_query, full_params)
            return webhook_response
          end
          bot.answer_inline_query(full_params)
        end

        # Same as respond_with, but for callback queries.
        def answer_callback_query(text, params = {})
          params, via_webhook = extract_via_webhook(params)
          full_params = params.merge(
            callback_query_id: payload['id'],
            text: text,
          )
          if via_webhook && render_webhook_response(:answer_callback_query, full_params)
            return webhook_response
          end
          bot.answer_callback_query(full_params)
        end

        # Same as respond_with, but for pre checkout queries.
        def answer_pre_checkout_query(ok, params = {})
          params, via_webhook = extract_via_webhook(params)
          full_params = params.merge(
            pre_checkout_query_id: payload['id'],
            ok: ok,
          )
          if via_webhook && render_webhook_response(:answer_pre_checkout_query, full_params)
            return webhook_response
          end
          bot.answer_pre_checkout_query(full_params)
        end

        def answer_shipping_query(ok, params = {})
          params, via_webhook = extract_via_webhook(params)
          full_params = params.merge(
            shipping_query_id: payload['id'],
            ok: ok,
          )
          if via_webhook && render_webhook_response(:answer_shipping_query, full_params)
            return webhook_response
          end
          bot.answer_shipping_query(full_params)
        end

        # Edit message from callback query.
        def edit_message(type, params = {})
          params, via_webhook = extract_via_webhook(params)
          full_params =
            if message_id = payload['inline_message_id'] # rubocop:disable Lint/AssignmentInCondition
              params.merge(inline_message_id: message_id)
            elsif message = payload['message'] # rubocop:disable Lint/AssignmentInCondition
              params.merge(chat_id: message['chat']['id'], message_id: message['message_id'])
            else
              raise 'Can not edit message without `inline_message_id` or `message`'
            end
          if via_webhook && render_webhook_response("edit_message_#{type}", full_params)
            return webhook_response
          end
          bot.public_send("edit_message_#{type}", full_params)
        end

        private

        # Splits the `via_webhook` flag out of the given params, returning both.
        def extract_via_webhook(params)
          params = params.dup
          via_webhook = params.delete(:via_webhook)
          [params, via_webhook]
        end
      end
    end
  end
end
