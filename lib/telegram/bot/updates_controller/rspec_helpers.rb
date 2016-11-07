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

  include Telegram::Bot::RSpec::ClientMatchers

  def dispatch(bot = self.bot, update = self.update)
    controller.dispatch_again(bot, update)
  end

  def dispatch_message(text, options = nil)
    options ||= respond_to?(:default_message_options) ? default_message_options : {}
    update = build_update :message, options.merge(text: text)
    dispatch bot, update
  end

  def build_update(type, content)
    deep_stringify type => content
  end

  def deep_stringify(input)
    case input
    when Array then input.map(&method(__callee__))
    when Hash then input.transform_keys(&:to_s).transform_values(&method(__callee__))
    else input
    end
  end

  # Matcher to check response. Make sure to define `let(:chat_id)`.
  def respond_with_message(expected)
    send_telegram_message(bot, expected, chat_id: chat_id)
  end
end
