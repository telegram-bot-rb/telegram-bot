# frozen_string_literal: true

require 'telegram/bot/rspec'
require 'telegram/bot/rspec/message_helpers'

# Shared helpers for testing widget query updates.
#
# It is included into groups tagged with `:widget_query`, and overrides `subject`,
# `payload`, `message_id` and `data` there: define the last two inside of the tagged group.
# It relies on `from` and `chat` from 'telegram/bot/message_helpers', so they can be
# customized as usual.
RSpec.shared_context 'telegram/bot/widget_query' do
  subject { -> { dispatch widget_query: payload } }
  let(:payload) do
    {id: widget_query_id, from: from, chat: chat, message_id: message_id, data: data}
  end
  let(:widget_query_id) { '11' }
  let(:message_id) { 22 }
  let(:data) { raise '`let(:data) { "widget query data here" }` is required' }

  # Matcher to check that message with the widget got edited.
  # To check that widget's state is changed use `edit_current_message(:widget_data, ...)`.
  def edit_current_message(type, options = {})
    description = 'edit current message'
    options = options.merge(
      message_id: message_id,
      chat_id: chat_id,
    )
    Telegram::Bot::RSpec::ClientMatchers::MakeTelegramRequest.new(
      bot, :"editMessage#{type.to_s.camelize}", description: description
    ).with(hash_including(options))
  end

  # Matcher to check that widget query is answered.
  # Without arguments it matches answer with any data and without data at all.
  def answer_widget_query(data = nil, options = {})
    description = data.nil? ? 'answer widget query' : "answer widget query with #{data.inspect}"
    data = a_string_matching(data) if data.is_a?(Regexp)
    options = options.merge(widget_query_id: payload[:id])
    options = options.merge(data: data) unless data.nil?
    Telegram::Bot::RSpec::ClientMatchers::MakeTelegramRequest.new(
      bot, :answerWidgetQuery, description: description
    ).with(hash_including(options))
  end
end

Telegram::Bot::RSpec.with_include_context do |config|
  config.include_context 'telegram/bot/widget_query', :widget_query
end
