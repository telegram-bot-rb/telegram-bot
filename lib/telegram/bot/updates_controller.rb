require 'abstract_controller'
require 'active_support/callbacks'
require 'active_support/version'

module Telegram
  module Bot
    # Base class to create update processors. With callbacks, session and helpers.
    #
    # Define public methods for each command and they will be called when
    # update has this command. Message is automatically parsed and
    # words are passed as method arguments. Be sure to use default values and
    # splat arguments in every action method to not get errors, when user
    # sends command without necessary args / with extra args.
    #
    #     def start(token = nil, *)
    #       if token
    #         # ...
    #       else
    #         # ...
    #       end
    #     end
    #
    #     def help(*)
    #       reply_with :message, text:
    #     end
    #
    # To process plain text messages (without commands) or other updates just
    # define public method with name of payload type. They will receive payload
    # as an argument.
    #
    #     def message(message)
    #       reply_with :message, text: "Echo: #{message['text']}"
    #     end
    #
    #     def inline_query(query)
    #       answer_inline_query results_for_query(query), is_personal: true
    #     end
    #
    #     # To process conflicting commands (`/message args`) just use `on_` prefix:
    #     def on_message(*args)
    #       # ...
    #     end
    #
    # To process update run:
    #
    #     ControllerClass.dispatch(bot, update)
    #
    # There is also ability to run action without update:
    #
    #     ControllerClass.new(bot, from: telegram_user, chat: telegram_chat).
    #       process(:help, *args)
    #
    class UpdatesController < AbstractController::Base
      abstract!

      require 'telegram/bot/updates_controller/session'
      require 'telegram/bot/updates_controller/log_subscriber'
      require 'telegram/bot/updates_controller/instrumentation'
      require 'telegram/bot/updates_controller/reply_helpers'
      autoload :CallbackQueyContext, 'telegram/bot/updates_controller/callback_query_context'
      autoload :MessageContext, 'telegram/bot/updates_controller/message_context'
      autoload :Botan, 'telegram/bot/updates_controller/botan'

      include AbstractController::Callbacks
      # Redefine callbacks with default terminator.
      if ActiveSupport.gem_version >= Gem::Version.new('5')
        define_callbacks  :process_action,
                          skip_after_callbacks_if_terminated: true
      else
        define_callbacks  :process_action,
                          terminator: ->(_, result) { result == false },
                          skip_after_callbacks_if_terminated: true
      end

      include AbstractController::Translation
      include ReplyHelpers
      prepend Instrumentation
      extend Session::ConfigMethods

      autoload :TypedUpdate, 'telegram/bot/updates_controller/typed_update'

      PAYLOAD_TYPES = %w(
        message
        inline_query
        chosen_inline_result
        callback_query
      ).freeze
      CMD_REGEX = %r{\A/([a-z\d_]{,31})(@(\S+))?(\s|$)}i
      CONFLICT_CMD_REGEX = Regexp.new("^(#{PAYLOAD_TYPES.join('|')}|\\d)")

      class << self
        # Initialize controller and process update.
        def dispatch(*args)
          new(*args).dispatch
        end

        # Overrid it to filter or transform commands.
        # Default implementation is to convert to downcase and add `on_` prefix
        # for conflicting commands.
        def action_for_command(cmd)
          cmd.downcase!
          cmd.match(CONFLICT_CMD_REGEX) ? "on_#{cmd}" : cmd
        end

        # Fetches command from text message. All subsequent words are returned
        # as arguments.
        # If command has mention (eg. `/test@SomeBot`), it returns commands only
        # for specified username. Set `username` to `true` to accept
        # any commands.
        def command_from_text(text, username = nil)
          return unless text
          match = text.match CMD_REGEX
          return unless match
          return if match[3] && username != true && match[3] != username
          [match[1], text.split.drop(1)]
        end
      end

      attr_internal_reader :update, :bot, :payload, :payload_type, :is_command
      alias_method :command?, :is_command
      delegate :username, to: :bot, prefix: true, allow_nil: true

      # Second argument can be either update object with hash access & string
      # keys or Hash with `:from` or `:chat` to override this values and assume
      # that update is nil.
      def initialize(bot = nil, update = nil)
        if update.is_a?(Hash) && (update.key?(:from) || update.key?(:chat))
          options = update
          update = nil
        end
        @_update = update
        @_bot = bot
        @_chat, @_from = options && options.values_at(:chat, :from)

        payload_data = nil
        update && PAYLOAD_TYPES.find do |type|
          item = update[type]
          payload_data = [item, type] if item
        end
        @_payload, @_payload_type = payload_data
      end

      # Accessor to `'chat'` field of payload. Can be overriden with `chat` option
      # for #initialize.
      def chat
        @_chat || payload && payload['chat']
      end

      # Accessor to `'from'` field of payload. Can be overriden with `from` option
      # for #initialize.
      def from
        @_from || payload && payload['from']
      end

      # Processes current update.
      def dispatch
        @_is_command, action, args = action_for_payload
        process(action, *args)
      end

      # Calculates action name and args for payload.
      # Uses `action_for_#{payload_type}` methods.
      # If this method doesn't return anything
      # it uses fallback with action same as payload type.
      # Returns array `[is_command?, action, args]`.
      def action_for_payload
        send("action_for_#{payload_type}") || [false, payload_type, [payload]]
      end

      # If payload is a message with command, then returned action is an
      # action for this command.
      # Separate method, so it can be easily overriden (ex. MessageContext).
      def action_for_message
        cmd, args = self.class.command_from_text(payload['text'], bot_username)
        cmd &&= self.class.action_for_command(cmd)
        [true, cmd, args] if cmd
      end

      def action_for_inline_query
        [false, payload_type, [payload['query'], payload['offset']]]
      end

      def action_for_chosen_inline_result
        [false, payload_type, [payload['result_id'], payload['query']]]
      end

      def action_for_callback_query
        [false, payload_type, [payload['data']]]
      end

      # Silently ignore unsupported messages.
      # Params are `action, *args`.
      def action_missing(*)
      end

      ActiveSupport.run_load_hooks('telegram.bot.updates_controller', self)
    end
  end
end
