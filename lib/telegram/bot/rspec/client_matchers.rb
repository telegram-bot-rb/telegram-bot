module Telegram
  module Bot
    module RSpec
      # Proxy that uses RSpec::Mocks::ArgListMatcher when it's available.
      # Otherwise just performs `#==` match.
      #
      # Also allows to check argumets with custom block.
      class ArgListMatcher
        attr_reader :expected, :expected_proc

        def initialize(*args, &block)
          @expected_proc = block if block_given?
          @expected =
            if mocks_matcher?
              ::RSpec::Mocks::ArgumentListMatcher.new(*args)
            else
              args
            end
        end

        def args_match?(*actual)
          if expected_proc
            expected_proc[*actual]
            true
          elsif mocks_matcher?
            expected.args_match?(*actual)
          else
            expected == actual
          end
        end

        def args
          mocks_matcher? ? expected.args : expected
        end

        def mocks_matcher?
          defined?(::RSpec::Mocks::ArgumentListMatcher)
        end

        def to_s
          if mocks_matcher?
            expected.expected_args.inspect
          elsif expected_proc
            '(proc matcher)'
          else
            expected.inspect
          end
        end
      end

      # Matchers to test requests to Telegram API.
      #
      # Complex matchers requires `rspec-mocks` to be installed.
      module ClientMatchers
        class MakeTelegramRequest < ::RSpec::Matchers::BuiltIn::BaseMatcher
          EXPECTATION_TYPES = {
            exactly: :==,
            at_most: :>=,
            at_least: :<=,
          }.freeze

          attr_reader :performed_requests, :description

          def initialize(bot, action, description: nil)
            @bot = bot
            @action = action
            @description = description || "make #{action} telegram request"
            exactly(1)
          end

          def matches?(proc) # rubocop:disable AbcSize
            raise ArgumentError, 'matcher only supports block expectations' unless proc.is_a?(Proc)
            original_requests_count = bot.requests[action].count
            proc.call
            @performed_requests = bot.requests[action].drop(original_requests_count)
            @matching_requests_count = performed_requests.count do |request|
              !arg_list_matcher || arg_list_matcher.args_match?(request)
            end
            expectation_method = EXPECTATION_TYPES[expectation_type]
            expected_number.public_send(expectation_method, matching_requests_count)
          end

          def with(*args, &block)
            @arg_list_matcher = ArgListMatcher.new(*args, &block)
            self
          end

          EXPECTATION_TYPES.each_key do |type|
            define_method type do |count|
              @expectation_type = type
              @expected_number = Integer(count)
              self
            end
          end

          def times
            self
          end

          def failure_message
            "expected to #{base_message}"
          end

          def failure_message_when_negated
            "expected not to #{base_message}"
          end

          def supports_block_expectations?
            true
          end

          private

          attr_reader :bot, :action, :expectation_type, :expected_number,
            :arg_list_matcher, :matching_requests_count

          def base_message
            "make #{expectation_type.to_s.tr('_', ' ')} #{expected_number} " \
              "#{bot.inspect}.#{action} requests,".tap do |msg|
              msg << " with #{arg_list_matcher}," if arg_list_matcher
              msg << " but made #{matching_requests_count}"
              if performed_requests
                actual_args = performed_requests.map(&:inspect).join(', ')
                msg << ", and #{performed_requests.count} with #{actual_args}"
              end
            end
          end
        end

        # Check that bot performed request to telegram API:
        #
        #   expect { dispatch_message('Hi!') }.
        #     to make_telegram_request(bot, :sendMessage).
        #     with(text: 'Hello!', chat_id: chat_id)
        def make_telegram_request(bot, action)
          MakeTelegramRequest.new(bot, action)
        end

        # Helper for asserting message is sent. Note that options are checked
        # with `hash_including`. For strict checks use #make_telegram_request.
        def send_telegram_message(bot, text = nil, options = {})
          description = "send telegram message #{text.inspect}"
          text = a_string_matching(text) if text.is_a?(Regexp)
          options = options.merge(text: text) if text
          MakeTelegramRequest.new(bot, :sendMessage, description: description).
            with(hash_including(options))
        end
      end
    end
  end
end
