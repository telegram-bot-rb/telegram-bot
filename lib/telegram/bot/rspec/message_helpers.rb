# Shared helpers for testing message updates.
RSpec.shared_context 'telegram/bot/message_helpers' do
  let(:default_message_options) { {from: from, chat: chat} }
  let(:from) { {id: from_id} }
  let(:from_id) { 123 }
  let(:chat) { {id: chat_id} }
  let(:chat_id) { 456 }

  # Shortcut for dispatching messages with default params.
  def dispatch_message(text, options = {})
    dispatch message: default_message_options.merge(options).merge(text: text)
  end

  # Dispatch command message.
  def dispatch_command(cmd, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    args.unshift("/#{cmd}")
    dispatch_message(args.join(' '), options)
  end

  # Matcher to check response. Make sure to define `let(:chat_id)`.
  def respond_with_message(expected = Regexp.new(''))
    raise 'Define chat_id to use respond_with_message' unless defined?(chat_id)
    send_telegram_message(bot, expected, chat_id: chat_id)
  end
end
