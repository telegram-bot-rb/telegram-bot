require 'telegram/bot/rspec/message_helpers'
require 'telegram/bot/rspec/callback_query_helpers'

RSpec.shared_context 'telegram/bot/integration' do
  include Telegram::Bot::RSpec::ClientMatchers
  include_context 'telegram/bot/message_helpers'

  let(:bot) { Telegram.bot }
  let(:controller_path) do
    route_name = Telegram::Bot::RoutesHelper.route_name_for_bot(bot)
    Rails.application.routes.url_helpers.public_send("#{route_name}_path")
  end
  let(:request_headers) do
    {
      'ACCEPT' => 'application/json',
      'Content-Type' => 'application/json',
    }
  end
  let(:clear_session?) { described_class.respond_to?(:session_store) }
  before { described_class.session_store.try!(:clear) if clear_session? }

  # Process update.
  def dispatch(update)
    if ActionPack::VERSION::MAJOR >= 5
      post(controller_path, params: update.to_json, headers: request_headers)
    else
      post(controller_path, update.to_json, request_headers)
    end
  end
end

RSpec.configure do |config|
  if config.respond_to?(:include_context)
    config.include_context 'telegram/bot/integration', :telegram_bot
  end
end
