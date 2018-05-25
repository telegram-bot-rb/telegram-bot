module Telegram
  module Bot
    module RSpec
      autoload :ClientMatchers, 'telegram/bot/rspec/client_matchers'

      module_function

      # Yelds a block if `include_context` is supported.
      def with_include_context
        ::RSpec.configure do |config|
          yield(config) if config.respond_to?(:include_context)
        end
      end
    end
  end
end
