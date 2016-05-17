require 'json'
require 'httpclient'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/keys'
require 'telegram/bot/debug_client'

module Telegram
  module Bot
    class Client
      URL_TEMPLATE = 'https://api.telegram.org/bot%s/'.freeze

      autoload :TypedResponse, 'telegram/bot/client/typed_response'
      include DebugClient

      class << self
        # Accepts different options to initialize bot.
        def wrap(input)
          case input
          when self then input
          when Array then input.map(&method(__callee__))
          when Hash then
            input = input.stringify_keys
            new input['token'], input['username'], botan: input['botan']
          when Symbol
            Telegram.bots[input] or
              raise "Bot #{input} not configured, check Telegram.bots_config."
          else
            new(input)
          end
        end

        # Prepend TypedResponse module.
        def typed_response!
          prepend TypedResponse
        end

        # Encodes nested hashes as json.
        def prepare_body(body)
          body = body.dup
          body.each do |k, val|
            body[k] = val.to_json if val.is_a?(Hash) || val.is_a?(Array)
          end
        end
      end

      attr_reader :client, :token, :username, :base_uri, :botan

      def initialize(token, username = nil, botan: nil)
        @client = HTTPClient.new
        @token = token
        @username = username
        @base_uri = format URL_TEMPLATE, token
        @botan = Botan.new(botan) if botan
      end

      def request(action, body = {}) # rubocop:disable PerceivedComplexity
        res = http_request("#{base_uri}#{action}", self.class.prepare_body(body))
        status = res.status
        return JSON.parse(res.body) if 300 > status
        result = JSON.parse(res.body) rescue nil # rubocop:disable RescueModifier
        err_msg = "#{res.reason}: #{result && result['description'] || '-'}"
        if result
          # NotFound is raised only for valid responses from Telegram
          raise NotFound, err_msg if 404 == status
          raise StaleChat, err_msg if StaleChat.match_response?(result)
        end
        raise Error, err_msg
      end

      %w(
        answerCallbackQuery
        answerInlineQuery
        forwardMessage
        getFile
        getMe
        getUpdates
        getUserProfilePhotos
        kickChatMember
        sendAudio
        sendChatAction
        sendContact
        sendDocument
        sendLocation
        sendMessage
        sendPhoto
        sendSticker
        sendVenue
        sendVideo
        sendVoice
        setWebhook
        unbanChatMember
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
        "#<#{self.class.name}##{object_id}(#{@username})>"
      end
    end
  end
end
