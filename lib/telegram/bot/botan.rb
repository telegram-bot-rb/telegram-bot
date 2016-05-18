module Telegram
  module Bot
    class Botan
      TRACK_URI = 'https://api.botan.io/track'.freeze

      autoload :ControllerHelpers, 'telegram/bot/botan/controller_helpers'
      class Error < Bot::Error; end

      include DebugClient

      attr_reader :client, :token

      def initialize(token)
        @client = HTTPClient.new
        @token = token
      end

      def track(event, uid, payload = {})
        res = http_request(
          :post,
          TRACK_URI,
          {token: token, name: event, uid: uid},
          payload.to_json,
        )
        status = res.status
        return JSON.parse(res.body) if 300 > status
        result = JSON.parse(res.body) rescue nil # rubocop:disable RescueModifier
        err_msg = "#{res.reason}: #{result && result['info'] || '-'}"
        raise Error, err_msg
      end

      def http_request(method, uri, query, body)
        client.request(method, uri, query, body)
      end
    end
  end
end
