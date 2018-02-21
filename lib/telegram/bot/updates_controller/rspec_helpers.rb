require 'telegram/bot/updates_controller/testing'

RSpec.shared_context 'telegram/bot/updates_controller' do
  let(:controller_class) { described_class }
  let(:controller) do
    controller_class.new(bot, update).tap do |x|
      x.extend Telegram::Bot::UpdatesController::Testing
    end
  end
  let(:update) { build_update(payload_type, payload) }
  let(:payload_type) { :some_type }
  let(:payload) { double(:payload) }
  let(:bot) { Telegram::Bot::ClientStub.new(bot_name) }
  let(:bot_name) { 'bot' }
  let(:session) { controller.send(:session) }
  let(:from_id) { 123 }
  let(:chat_id) { 456 }
  let(:default_message_options) { {from: {id: from_id}, chat: {id: chat_id}} }

  include Telegram::Bot::RSpec::ClientMatchers

  def dispatch(bot = self.bot, update = self.update)
    controller.dispatch_again(bot, update)
  end

  def dispatch_message(text, options = {})
    update = build_update :message, default_message_options.merge(options).merge(text: text)
    dispatch bot, update
  end

  def build_update(type, content)
    deep_stringify type => content
  end

  def deep_stringify(input)
    case input
    when Array then input.map(&method(__callee__))
    when Hash then input.map { |k, v| [k.to_s, deep_stringify(v)] }.to_h
    else input
    end
  end

  # Matcher to check response. Make sure to define `let(:chat_id)`.
  def respond_with_message(expected)
    send_telegram_message(bot, expected, chat_id: chat_id)
  end
end

RSpec.configure do |config|
  if config.respond_to?(:include_context)
    config.include_context 'telegram/bot/updates_controller', type: :telegram_bot_controller
  end
end
