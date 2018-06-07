require 'telegram/bot/rspec'
require 'telegram/bot/rspec/message_helpers'

# Shared helpers for testing callback query updates.
RSpec.shared_context 'telegram/bot/callback_query' do
  include_context 'telegram/bot/message_helpers'

  subject { -> { dispatch callback_query: payload } }
  let(:payload) { {id: callback_query_id, from: from, message: message, data: data} }
  let(:callback_query_id) { 11 }
  let(:message_id) { 22 }
  let(:message) { {message_id: message_id, chat: chat, text: 'message text'} }
  let(:data) { raise '`let(:data) { "callback query data here" }` is required' }

  # Matcher to check that origin message got edited.
  def edit_current_message(type, options = {})
    description = 'edit current message'
    options = options.merge(
      message_id: message[:message_id],
      chat_id: chat_id,
    )
    Telegram::Bot::RSpec::ClientMatchers::MakeTelegramRequest.new(
      bot, :"editMessage#{type.to_s.camelize}", description: description
    ).with(hash_including(options))
  end

  # Matcher to check that callback query is answered.
  def answer_callback_query(text = Regexp.new(''), options = {})
    description = "answer callback query with #{text.inspect}"
    text = a_string_matching(text) if text.is_a?(Regexp)
    options = options.merge(
      callback_query_id: payload[:id],
      text: text,
    )
    Telegram::Bot::RSpec::ClientMatchers::MakeTelegramRequest.new(
      bot, :answerCallbackQuery, description: description
    ).with(hash_including(options))
  end
end
