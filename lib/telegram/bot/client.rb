require 'active_support/core_ext/hash/keys'
require 'json'
require 'httpclient'

module Telegram
  module Bot
    class Client
      SERVER = 'https://api.telegram.org'.freeze
      URL_TEMPLATE = '%<server>s/bot%<token>s/'.freeze

      autoload :TypedResponse, 'telegram/bot/client/typed_response'
      prepend Async
      include DebugClient

      require 'telegram/bot/client/api_helper'
      include ApiHelper

      class << self
        # Accepts different options to initialize bot.
        def wrap(input, **options)
          case input
          when Symbol then by_id(input) or raise "#{name} #{input.inspect} not configured"
          when self   then input
          when Hash   then new(**input.symbolize_keys, **options)
          else        new(input, **options)
          end
        end

        def by_id(id)
          Telegram.bots[id]
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

        def prepare_async_args(action, body = {})
          [action.to_s, Async.prepare_hash(prepare_body(body))]
        end

        def error_for_response(response)
          result = JSON.parse(response.body) rescue nil # rubocop:disable RescueModifier
          return Error.new(response.reason) unless result
          message = result['description'] || '-'
          # This errors are raised only for valid responses from Telegram
          case response.status
          when 403 then Forbidden.new(message)
          when 404 then NotFound.new(message)
          else Error.new("#{response.reason}: #{message}")
          end
        end
      end

      attr_reader :client, :token, :username, :base_uri

      def initialize(token = nil, username = nil, server: SERVER, **options)
        @client = HTTPClient.new
        @token = token || options[:token]
        @username = username || options[:username]
        @base_uri = format(URL_TEMPLATE, server: server, token: self.token)
      end

      def request(action, body = {})
        response = http_request("#{base_uri}#{action}", self.class.prepare_body(body))
        raise self.class.error_for_response(response) if response.status >= 300
        JSON.parse(response.body)
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
