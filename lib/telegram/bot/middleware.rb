if ActiveSupport.gem_version >= Gem::Version.new('5.0.0.rc1')
  require 'active_support/json'
  require 'active_support/logger'
  require 'active_support/core_ext/hash/indifferent_access'
end
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
        update = if ActiveSupport.gem_version >= Gem::Version.new('5.0.0.rc1')
                   ActionDispatch::Request.new(env).request_parameters
                 else
                   env['action_dispatch.request.request_parameters']
                 end
        controller.dispatch(bot, update)
        [200, {}, ['']]
      end

      def inspect
        "#<#{self.class.name}(#{controller.try!(:name)})>"
      end
    end
  end
end
