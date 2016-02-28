module Telegram
  module Bot
    # Stubbed client for tests. Saves all requests into #requests hash.
    class ClientStub < Client
      attr_reader :requests

      def initialize(username = nil)
        @username = username
        reset
      end

      def reset
        @requests = Hash.new { |h, k| h[k] = [] }
      end

      def request(action, body)
        requests[action.to_sym] << body
      end
    end
  end
end
