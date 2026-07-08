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
        controller.dispatch(bot, update, request)
        response = request.get_header(UpdatesController::WEBHOOK_RESPONSE_ENV_KEY)
        if response
          [200, {'Content-Type' => 'application/json'}, [response]]
        else
          [200, {}, ['']]
        end
      end

      def inspect
        "#<#{self.class.name}(#{controller&.name})>"
      end
    end
  end
end
