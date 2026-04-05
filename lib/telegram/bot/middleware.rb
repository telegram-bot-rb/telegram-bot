# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/json'
require 'action_dispatch'

module Telegram
  module Bot
    class Middleware
      attr_reader :bot, :controller

      def initialize(bot, controller)
        @bot = bot
        @controller = controller
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        update = request.request_parameters
        if webhook_token_matches?(bot, request)
          controller.dispatch(bot, update, request)
          [200, {}, ['']]
        else
          [403, {}, ['Forbidden']]
        end
      end

      def inspect
        "#<#{self.class.name}(#{controller&.name})>"
      end

      private

      def webhook_token_matches?(bot, request)
        request.headers['X-Telegram-Bot-Api-Secret-Token'] == bot.webhook_token
      end
    end
  end
end
