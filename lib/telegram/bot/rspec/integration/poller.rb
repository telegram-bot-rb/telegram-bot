require 'telegram/bot/rspec/integration/shared'

RSpec.shared_context 'telegram/bot/integration/poller' do
  include_context 'telegram/bot/integration/shared'
  let(:controller_class) { described_class }

  def dispatch(update)
    controller_class.dispatch(bot, update.as_json)
  end
end

Telegram::Bot::RSpec.with_include_context do |config|
  config.include_context 'telegram/bot/integration/poller', telegram_bot: :poller
end
