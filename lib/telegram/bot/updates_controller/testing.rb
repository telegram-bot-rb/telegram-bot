module Telegram
  module Bot
    class UpdatesController
      module Testing
        IVARS_TO_KEEP = %i[@_session].freeze

        # Perform multiple dispatches on same instance.
        def dispatch_again(bot = nil, update = nil, webhook_request = nil)
          recycle!
          initialize(bot, update, webhook_request)
          dispatch
        end

        # Cleans controller between dispatches.
        # Seems like there is nothing to clean between requests for now:
        # everything will be rewriten with #initialize.
        #
        # With `full` set to `true` it'll clear all cached instance variables.
        def recycle!(full = false)
          return unless full
          (instance_variables - IVARS_TO_KEEP).each do |ivar|
            remove_instance_variable(ivar)
          end
        end

        protected

        # Stubs session.
        def session
          @_session ||= Session::NullSessionHash.new
        end
      end
    end
  end
end
