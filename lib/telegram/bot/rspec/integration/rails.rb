require 'telegram/bot/rspec/integration/shared'

RSpec.shared_context 'telegram/bot/integration/rails', type: :request do
  include_context 'telegram/bot/integration/shared'

  let(:controller_path) do
    route_name = Telegram::Bot::RoutesHelper.route_name_for_bot(bot)
    Rails.application.routes.url_helpers.public_send("#{route_name}_path")
  end
  let(:request_headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
    }
  end

  def dispatch(update)
    if ActionPack::VERSION::MAJOR >= 5
      post(controller_path, params: update.to_json, headers: request_headers)
    else
      post(controller_path, update.to_json, request_headers)
    end
  end
end

Telegram::Bot::RSpec.with_include_context do |config|
  config.include_context 'telegram/bot/integration/rails', telegram_bot: :rails
end
