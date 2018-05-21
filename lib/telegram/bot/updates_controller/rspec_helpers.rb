require 'telegram/bot/updates_controller/testing'
require 'telegram/bot/rspec/message_helpers'

RSpec.shared_context 'telegram/bot/updates_controller' do
  include Telegram::Bot::RSpec::ClientMatchers
  include_context 'telegram/bot/message_helpers'

  let(:controller_class) { described_class }
  let(:controller) do
    controller_class.new(*controller_args).tap do |x|
      x.extend Telegram::Bot::UpdatesController::Testing
    end
  end
  let(:controller_args) { [bot, deep_stringify(update)] }
  let(:update) { {payload_type => payload} }
  let(:payload_type) { :some_type }
  let(:payload) { double(:payload) }
  let(:bot) { Telegram::Bot::ClientStub.new(bot_name) }
  let(:bot_name) { 'bot' }
  let(:session) { controller.send(:session) }

  # Process update.
  def dispatch(update = self.update, bot = self.bot)
    controller.dispatch_again(bot, deep_stringify(update))
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

RSpec.configure do |config|
  if config.respond_to?(:include_context)
    config.include_context 'telegram/bot/updates_controller', type: :telegram_bot_controller
  end
end
