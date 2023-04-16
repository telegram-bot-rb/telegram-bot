require 'abstract_controller'
require 'active_support/core_ext/string/inflections'
require 'active_support/callbacks'
require 'active_support/version'

module Telegram
  module Bot
    # Base class to create update processors. With callbacks, session and helpers.
    #
    # Public methods ending with `!` handle messages with commands.
    # Message text is automatically parsed  into method arguments.
    # Be sure to use default values and
    # splat arguments in every action method to not get errors, when user
    # sends command without necessary args / with extra args.
    #
    #     def start!(token = nil, *)
    #       if token
    #         # ...
    #       else
    #         # ...
    #       end
    #     end
    #
    #     def help!(*)
    #       respond_with :message, text:
    #     end
    #
    # To process plain text messages (without commands) or other updates just
    # define public method with name of payload type.
    # By default they receive payload as an argument, but some of them are called
    # with more usefuk args:
    #
    #     def message(message)
    #       respond_with :message, text: "Echo: #{message['text']}"
    #     end
    #
    #     def inline_query(query, offset)
    #       answer_inline_query results_for_query(query, offset), is_personal: true
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
    class UpdatesController < AbstractController::Base # rubocop:disable ClassLength
      abstract!

      %w[
        Commands
        Instrumentation
        LogSubscriber
        ReplyHelpers
        Rescue
        Session
        Translation
      ].each { |name| require "telegram/bot/updates_controller/#{name.underscore}" }

      %w[
        CallbackQueryContext
        MessageContext
        TypedUpdate
      ].each { |mod| autoload mod, "telegram/bot/updates_controller/#{mod.underscore}" }

      include AbstractController::Callbacks
      # Redefine callbacks with default terminator.
      if ActiveSupport::VERSION::MAJOR >= 5
        define_callbacks  :process_action,
                          skip_after_callbacks_if_terminated: true
      else
        define_callbacks  :process_action,
                          terminator: ->(_, result) { result == false },
                          skip_after_callbacks_if_terminated: true
      end

      include Commands
      include Rescue
      include ReplyHelpers
      include Translation
      # Add instrumentations hooks at the bottom, to ensure they instrument
      # all the methods properly.
      include Instrumentation

      extend Session::ConfigMethods

      PAYLOAD_TYPES = %w[
        message
        edited_message
        channel_post
        edited_channel_post
        inline_query
        chosen_inline_result
        callback_query
        shipping_query
        pre_checkout_query
        poll
        poll_answer
        my_chat_member
        chat_member
      ].freeze

      class << self
        # Initialize controller and process update.
        def dispatch(*args)
          new(*args).dispatch
        end

        def payload_from_update(update)
          update && PAYLOAD_TYPES.find do |type|
            item = update[type]
            return [item, type] if item
          end
        end
      end

      attr_internal_reader :bot, :payload, :payload_type, :update, :webhook_request
      delegate :username, to: :bot, prefix: true, allow_nil: true

      # `update` can be either update object with hash access & string
      # keys or Hash with `:from` or `:chat` to override this values and assume
      # that update is nil.
      # ActionDispatch::Request object is passed in `webhook_request` when bot running
      # in webhook mode.
      def initialize(bot = nil, update = nil, webhook_request = nil)
        if update.is_a?(Hash) && (update.key?(:from) || update.key?(:chat))
          options = update
          update = nil
        end
        @_bot = bot
        @_update = update
        @_chat, @_from = options && options.values_at(:chat, :from)
        @_payload, @_payload_type = self.class.payload_from_update(update)
        @_webhook_request = webhook_request
      end

      # Accessor to `'chat'` field of payload. Also tries `'chat'` in `'message'`
      # when there is no such field in payload.
      #
      # Can be overriden with `chat` option for #initialize.
      def chat
        @_chat ||=
          if payload
            if payload.is_a?(Hash)
              payload['chat'] || payload['message'] && payload['message']['chat']
            else
              payload.try(:chat) || payload.try(:message).try!(:chat)
            end
          end
      end

      # Accessor to `'from'` field of payload. Can be overriden with `from` option
      # for #initialize.
      def from
        @_from ||= payload.is_a?(Hash) ? payload['from'] : payload.try(:from)
      end

      # Processes current update.
      def dispatch
        action, args = action_for_payload
        process(action, *args)
      end

      attr_internal_reader :action_options

      # It provides support for passing array as action, where first vaule
      # is action name and second is action metadata.
      # This metadata is stored inside action_options
      def process(action, *args)
        action, options = action if action.is_a?(Array)
        @_action_options = options || {}
        super
      end

      # There are multiple ways how action name is calculated for update
      # (see Commands, MessageContext, etc.). This method represents the
      # way how action was calculated for current udpate.
      #
      # Some of possible values are `:payload, :command, :message_context`.
      def action_type
        action_options[:type] || :payload
      end

      # Calculates action name and args for payload.
      # Uses `action_for_#{payload_type}` methods.
      # If this method doesn't return anything
      # it uses fallback with action same as payload type.
      # Returns array `[action, args]`.
      def action_for_payload
        if payload_type
          send("action_for_#{payload_type}") || action_for_default_payload
        else
          [:unsupported_payload_type, []]
        end
      end

      def action_for_default_payload
        [payload_type, [payload]]
      end

      def action_for_inline_query
        [payload_type, [payload['query'], payload['offset']]]
      end

      def action_for_chosen_inline_result
        [payload_type, [payload['result_id'], payload['query']]]
      end

      def action_for_callback_query
        [payload_type, [payload['data']]]
      end

      def action_for_poll_answer
        [payload_type, [payload['poll_id'], payload['option_ids']]]
      end

      # Silently ignore unsupported messages to not fail when user crafts
      # an update with usupported command, callback query context, etc.
      def action_missing(action, *_args)
        logger.debug { "The action '#{action}' is not defined in #{self.class.name}" } if logger
        nil
      end

      PAYLOAD_TYPES.each do |type|
        method = :"action_for_#{type}"
        alias_method method, :action_for_default_payload unless instance_methods.include?(method)
      end

      ActiveSupport.run_load_hooks('telegram.bot.updates_controller', self)
    end
  end
end
