# frozen_string_literal: true

module Telegram
  module Bot
    # Stubbed client for tests. Saves all requests into #requests hash.
    class ClientStub < Client
      attr_reader :requests

      module StubbedConstructor
        def new(*args, **kwargs)
          if self == ClientStub || !ClientStub.stub_all?
            super
          else
            ClientStub.new(*args, **kwargs)
          end
        end
      end

      class << self
        # Any call to Client.new will return ClientStub instance when `enabled` is true.
        # Can be used with a block.
        def stub_all!(enabled = true) # rubocop:disable Style/OptionalBooleanParameter
          Client.extend(StubbedConstructor) unless Client < StubbedConstructor
          return @_stub_all = enabled unless block_given?
          begin
            old = @_stub_all
            stub_all!(enabled)
            yield
          ensure
            stub_all!(old)
          end
        end

        def stub_all?
          @_stub_all
        end
      end

      def initialize(token = nil, username = nil, **options) # rubocop:disable Lint/MissingSuper
        @token = token || options[:token]
        @username = username || options[:username] || token
        reset
      end

      def reset
        @requests = Hash.new { |h, k| h[k] = [] }
      end

      def request(action, body = {})
        requests[action.to_sym] << body
      end
    end
  end
end
