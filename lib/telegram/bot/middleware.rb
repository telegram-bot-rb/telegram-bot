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
        [200, {}, ['']]
      end

      def inspect
        "#<#{self.class.name}(#{controller.try!(:name)})>"
      end
    end
  end
end
