require 'telegram/bot/client/api_helper'
require 'active_support/core_ext/string/inflections'

module Telegram
  module Bot
    class Client
      # Actions with type-casted results. Install `telegram-bot-types` gem first.
      module TypedResponse
        # First we define methods for every available api method to return `result`
        # field instead of object.
        ApiHelper.methods_list.each do |method|
          define_method(method.to_s.underscore) do |*args|
            super(*args)['result']
          end
        end

        # And then override some of them which has castable results.
        Types::Response::WRAPPED_METHODS.each do |method, type|
          define_method(method.to_s.underscore) do |*args|
            Types::Response.wrap(super(*args)['result'], type)
          end
        end
      end
    end
  end
end
