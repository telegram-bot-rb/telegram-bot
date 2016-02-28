require 'abstract_controller'
require 'active_support/callbacks'
require 'active_support/version'

module Telegram
  module Bot
    class UpdatesController < AbstractController::Base
      abstract!

      require 'telegram/bot/updates_controller/session'
      require 'telegram/bot/updates_controller/log_subscriber'
      require 'telegram/bot/updates_controller/instrumentation'

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
      prepend Instrumentation
      extend Session::ConfigMethods

      autoload :TypedUpdate, 'telegram/bot/updates_controller/typed_update'

      PAYLOAD_TYPES = %w(
        message
        inline_query
        chosen_inline_result
      ).freeze
      CMD_REGEX = %r{\A/([a-z\d_]{,31})(@(\S+))?(\s|$)}i
      CONFLICT_CMD_REGEX = Regexp.new("^(#{PAYLOAD_TYPES.join('|')}|\\d)")

      class << self
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
          [match[1], text.split(' ').drop(1)]
        end
      end

      attr_internal_reader :update, :bot, :payload, :payload_type, :is_command
      alias_method :command?, :is_command
      delegate :username, to: :bot, prefix: true, allow_nil: true

      def initialize(bot = nil, update = nil)
        @_update = update
        @_bot = bot

        update && PAYLOAD_TYPES.find do |type|
          item = update[type]
          next unless item
          @_payload = item
          @_payload_type = type
        end
      end

      def dispatch
        @_is_command, action, args = action_for_payload
        process(action, *args)
      end

      # Calculates action name and args for payload.
      # If payload is a message with command, then returned action is an
      # action for this command. Otherwise it's the same as payload type.
      # Returns array `[is_command?, action, args]`.
      def action_for_payload
        case payload_type
        when 'message'
          cmd, args = self.class.command_from_text(payload['text'], bot_username)
          cmd &&= self.class.action_for_command(cmd)
          [true, cmd, args] if cmd
        end || [false, payload_type, [payload]]
      end

      # Silently ignore unsupported messages.
      # Params are `action, *args`.
      def action_missing(*)
      end

      %w(chat from).each do |field|
        define_method(field) { payload[field] }
      end

      def reply_with(type, params)
        method = "send_#{type}"
        params = params.merge(
          chat_id: chat['id'],
          reply_to_message: payload['message_id'],
        )
        bot.public_send(method, params)
      end

      ActiveSupport.run_load_hooks('telegram.bot.updates_controller', self)
    end
  end
end
