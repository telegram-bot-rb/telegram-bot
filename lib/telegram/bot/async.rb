module Telegram
  module Bot
    # Telegram clients can perform requests in async way with
    # any job adapter (ActiveJob by default). Using Rails you don't need any
    # additional configuration. However you may want to enable async requests
    # by default with `async: true` in `secrets.yml`.
    #
    #   telegram:
    #     bots:
    #       chat_async:
    #         token: secret
    #         async: true # enable async mode for client
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
    # `#async=` sets global value for all threads,
    # while `#async(val, &block)` is thread-safe.
    #
    # It can be set with custom job class or classname. By default it defines
    # job classes for every client class, inherited from ApplicationRecord, which
    # can be accessed via `.default_async_job`. You can integrate it with any
    # other job provider by defining a class with `.perform_later(bot_id, *args)`
    # method. See Async::Job for implemetation.
    module Async
      # Used to track missing key in a hash in local variable.
      MISSING_VALUE = Object.new.freeze

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

        # Returns default_async_job if `true` is given,
        # treats String as a constant name, or bypasses any other values.
        def prepare_async_val(val)
          case val
          when true then default_async_job
          when String then Object.const_get(val)
          else val
          end
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

        # Thread-local hash to store async config for every client.
        def thread_store
          Thread.current[:telegram_bot_async] ||= {}
        end
      end

      attr_reader :id

      def initialize(*, id: nil, async: nil, **options)
        @id = id
        self.async = async
        super
      end

      # Sets default async value for all threads.
      # Uses `self.class.prepare_async_val` to prepare value.
      def async=(val)
        @async = self.class.prepare_async_val(val)
      end

      # Sets async value in a thread-safe way for the block.
      # Uses `self.class.prepare_async_val` to prepare value.
      #
      # If no block is given returns previously set value or the global one,
      # set by #async=.
      def async(val = true)
        thread_key = object_id
        thread_store = Async.thread_store
        return thread_store.fetch(thread_key) { @async } unless block_given?
        begin
          old_val = thread_store.fetch(thread_key) { MISSING_VALUE }
          thread_store[thread_key] = self.class.prepare_async_val(val)
          yield
        ensure
          if MISSING_VALUE == old_val
            thread_store.delete(thread_key)
          else
            thread_store[thread_key] = old_val
          end
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
