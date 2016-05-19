module Telegram
  module Bot
    # Telegram & Botan clients can perform requests in async way with
    # any job adapter (ActiveJob by default). Using Rails you don't need any
    # additional configuration. However you may want to enable async requests
    # by default with `async: true` in `secrets.yml`. Botan client doesn't inherit
    # async setting from client and must be configured separately.
    #
    #   telegram:
    #     bots:
    #       chat_async:
    #         token: secret
    #         async: true # enable async mode for client
    #         botan: botan_token # in this way botan will not be async
    #         botan: # in this way - it's in async mode
    #           token: botan_token
    #           async: true
    #
    # Without Rails To start using async requests
    # initialize client with `id` kwarg and make sure the client is
    # accessible via `Teletgram.bots[id]` in job worker. Or just use
    # `Telegram.bots_config=` for configuration.
    #
    # Being in async mode `#request` enqueues job instead to perform
    # http request instead of performing it directly.
    # Async behavior is controlled with `#async=` writer
    # and can be enabled/disabled for the block with `#async`:
    #
    #   client = Telegram::Bot::Client.new(**config, async: true)
    #   client.send_message(message)
    #   client.async(false) { client.send_message(other_one) }
    #
    # It can be set with custom job class or classname. By default it defines
    # job classes for every client class, inherited from ApplicationRecord, which
    # can be accessed via `.default_async_job`. You can integrate it with any
    # other job provider by defining a class with `.perform_later(bot_id, *args)`
    # method. See Async::Job for implemetation.
    module Async
      module Job
        class << self
          def included(base)
            base.singleton_class.send :attr_accessor, :client_class
          end
        end

        def perform(client_id, *args)
          client = self.class.client_class.wrap(client_id.to_sym)
          client.async(false) { client.request(*args) }
        end
      end

      module ClassMethods
        def default_async_job
          @default_async_job ||= begin
            begin
              ApplicationJob
            rescue NameError
              raise 'Define ApplicationJob class or setup #async= with custom job class'
            end
            klass = Class.new(ApplicationJob) { include Job }
            klass.client_class = self
            const_set(:AsyncJob, klass)
          end
        end

        # This is used in specs.
        def default_async_job=(val)
          @default_async_job = val
          remove_const(:AsyncJob) if const_defined?(:AsyncJob, false)
        end

        # Prepares argments for async job. ActiveJob doesn't support
        # Symbol in argumens. Also we can encode json bodies only once here,
        # so it would not be unnecessarily serialized-deserialized.
        #
        # This is stub method, which returns input. Every client class
        # must prepare args itself.
        def prepare_async_args(*args)
          args
        end
      end

      class << self
        def prepended(base)
          base.extend(ClassMethods)
        end

        # Transforms symbols to strings in hash values.
        def prepare_hash(hash)
          return hash unless hash.is_a?(Hash)
          hash = hash.dup
          hash.each { |key, val| hash[key] = val.to_s if val.is_a?(Symbol) }
        end
      end

      attr_reader :id

      def initialize(*, id: nil, async: nil, **options)
        @id = id
        self.async = async
        super
      end

      # Sets `@async` to `self.class.default_async_job` if `true` is given
      # or uses given value.
      # Pass custom job class to perform async calls with.
      def async=(val)
        @async =
          case val
          when true then self.class.default_async_job
          when String then const_get(val)
          else val
          end
      end

      # Returns value of `@async` if no block is given. Otherwise sets this value
      # for a block.
      def async(val = true)
        return @async unless block_given?
        begin
          old_val = @async
          self.async = val
          yield
        ensure
          @async = old_val
        end
      end

      # Uses job if #async is set.
      def request(*args)
        job_class = async
        return super unless job_class
        raise 'Can not enqueue job without client id' unless id
        job_class.perform_later(id.to_s, *self.class.prepare_async_args(*args))
      end
    end
  end
end
