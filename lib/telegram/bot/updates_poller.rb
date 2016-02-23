module Telegram
  module Bot
    # Supposed to be used in development environments only.
    class UpdatesPoller
      class << self
        @@instances = {} # rubocop:disable ClassVars

        def instances
          @@instances
        end

        # Create, start and add poller instnace to tracked instances list.
        def add(bot, controller)
          new(bot, controller).tap { |x| instances[bot] = x }
        end

        def start(bot_id, controller = nil)
          bot = bot_id.is_a?(Symbol) ? Telegram.bots[bot_id] : Client.wrap(bot_id)
          instance = controller ? new(bot, controller) : instances[bot]
          raise "Poller not found for #{bot_id.inspect}" unless instance
          instance.start
        end
      end

      DEFAULT_TIMEOUT = 5

      attr_reader :bot, :controller, :timeout, :offset, :logger, :running, :reload

      def initialize(bot, controller, **options)
        @logger = options.fetch(:logger) { defined?(Rails) && Rails.logger }
        @bot = bot
        @controller = controller
        @timeout = options.fetch(:timeout) { DEFAULT_TIMEOUT }
        @offset = options[:offset]
        @reload = options.fetch(:reload) { defined?(Rails) && Rails.env.development? }
      end

      def log(&block)
        logger.info(&block) if logger
      end

      def start
        return if running
        @running = true
        log { 'Started bot poller.' }
        while running
          begin
            fetch_updates do |update|
              controller.dispatch(bot, update)
            end
          rescue Interrupt
            @running = false
          rescue => e
            logger.error { ([e.message] + e.backtrace).join("\n") } if logger
          end
        end
        log { 'Stop polling bot updates.' }
      end

      def stop
        return unless running
        log { 'Killing polling thread.' }
        @running = false
      end

      def fetch_updates
        response = bot.get_updates(offset: offset, timeout: timeout)
        return unless response['ok'] && response['result'].any?
        reload! do
          response['result'].each do |update|
            @offset = update['update_id'] + 1
            yield update
          end
        end
      rescue Timeout::Error # rubocop:disable HandleExceptions
      end

      def reload!
        return yield unless reload
        ActionDispatch::Reloader.prepare!
        if controller.is_a?(Class) && controller.name
          @controller = Object.const_get(controller.name)
        end
        yield.tap { ActionDispatch::Reloader.cleanup! }
      end
    end
  end
end
