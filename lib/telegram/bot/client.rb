require 'json'
require 'httpclient'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/keys'

module Telegram
  module Bot
    class Client
      autoload :TypedResponse, 'telegram/bot/client/typed_response'

      URL_TEMPLATE = 'https://api.telegram.org/bot%s/'.freeze

      class << self
        # Accepts different options to initialize bot.
        def wrap(input)
          case input
          when self then input
          when Array then input.map(&method(__callee__))
          when Hash then
            input = input.stringify_keys
            new input['token'], input['username']
          else
            new(input)
          end
        end

        # Prepend TypedResponse module.
        def typed_response!
          prepend TypedResponse
        end
      end

      attr_reader :client, :token, :username, :base_uri

      def initialize(token, username = nil)
        @client = HTTPClient.new
        @token = token
        @username = username
        @base_uri = format URL_TEMPLATE, token
      end

      def debug!(dev = STDOUT)
        client.debug_dev = dev
      end

      def debug_off!
        client.debug_dev = nil
      end

      def request(action, data = {})
        res = http_request("#{base_uri}#{action}", data)
        status = res.status
        return JSON.parse(res.body) if 300 > status
        result = JSON.parse(res.body) rescue nil # rubocop:disable RescueModifier
        err_msg = "#{res.reason}: #{result && result['description'] || '-'}"
        # NotFound is raised only for valid responses from Telegram
        raise NotFound, err_msg if 404 == status && result
        raise Error, err_msg
      end

      %w(
        answerInlineQuery
        forwardMessage
        getFile
        getMe
        getUpdates
        getUserProfilePhotos
        sendAudio
        sendChatAction
        sendDocument
        sendLocation
        sendMessage
        sendPhoto
        sendSticker
        sendVideo
        sendVoice
        setWebhook
      ).each do |method|
        define_method(method.underscore) { |*args| request(method, *args) }
      end

      # Endpoint for low-level request. For easy host highjacking & instrumentation.
      # Params are not used directly but kept for instrumentation purpose.
      # You probably don't want to use this method directly.
      def http_request(uri, body)
        client.post(uri, body)
      end

      def inspect
        "#<Telegram::Bot::Client##{object_id}(#{@username})>"
      end
    end
  end
end
