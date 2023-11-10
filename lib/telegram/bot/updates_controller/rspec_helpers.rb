require 'telegram/bot/updates_controller/testing'
require 'telegram/bot/rspec/message_helpers'
require 'telegram/bot/rspec/callback_query_helpers'

RSpec.shared_context 'telegram/bot/updates_controller' do
  include Telegram::Bot::RSpec::ClientMatchers
  include_context 'telegram/bot/message_helpers'
  include_context 'telegram/bot/callback_query', :callback_query

  let(:controller_class) { described_class }
  let(:controller) do
    controller_class.new(*controller_args).tap do |x|
      x.extend Telegram::Bot::UpdatesController::Testing
    end
  end
  let(:controller_args) { [bot, deep_stringify(update), webhook_request] }
  let(:update) { {payload_type => payload} }
  let(:webhook_request) { nil }
  let(:payload_type) { :some_type }
  let(:payload) { double(:payload) }
  let(:bot) { Telegram::Bot::ClientStub.new(bot_name) }
  let(:bot_name) { 'bot' }
  let(:session) { controller.send(:session) }

  # Process update.
  def dispatch(update = self.update, bot = self.bot, webhook_request = self.webhook_request)
    controller.dispatch_again(bot, deep_stringify(update), webhook_request)
  end

  # Same as `.as_json` but mocks-friendly.
  def deep_stringify(input)
    case input
    when Array then input.map(&method(__callee__))
    when Hash then input.map { |k, v| [k.to_s, deep_stringify(v)] }.to_h
    else input
    end
  end
end

Telegram::Bot::RSpec.with_include_context do |config|
  config.include_context 'telegram/bot/updates_controller', type: :telegram_bot_controller
end
