require 'active_support/concern'
require 'action_dispatch/http/mime_type'
require 'action_dispatch/middleware/params_parser'

module Telegram
  module Bot
    class Middleware
      attr_reader :bot, :controller

      def initialize(bot, controller)
        @bot = bot
        @controller = controller
      end

      def call(env)
        update = env['action_dispatch.request.request_parameters']
        controller.dispatch(bot, update)
        [200, {}, '']
      end

      def inspect
        "#<#{self.class.name}(#{controller.try!(:name)})>"
      end
    end
  end
end
