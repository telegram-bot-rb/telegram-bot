require 'active_support/core_ext/hash/keys'

module Telegram
  module Bot
    module Initializers
      # Accepts different options to initialize bot.
      def wrap(input, **options)
        case input
        when Symbol then by_id(input) or raise "#{name} #{input.inspect} not configured"
        when self   then input
        when Hash   then new(**input.symbolize_keys, **options)
        else        new(input, **options)
        end
      end

      def by_id(_id)
        raise 'Not implemented'
      end
    end
  end
end
