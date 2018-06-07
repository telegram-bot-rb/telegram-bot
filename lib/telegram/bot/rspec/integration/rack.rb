require 'telegram/bot/rspec/integration/shared'
require 'rack/test'

RSpec.shared_context 'telegram/bot/integration/rack' do
  include_context 'telegram/bot/integration/shared'
  include Rack::Test::Methods

  let(:request_path) { raise '`let(:request_path) { path to bot }` is required' }
  let(:app) { raise '`let(:app) { your rack app here }` is required' }
  let(:request_headers) do
    {
      'ACCEPT' => 'application/json',
      'CONTENT_TYPE' => 'application/json',
    }
  end

  def dispatch(update)
    post request_path, update.to_json, request_headers
  end
end

Telegram::Bot::RSpec.with_include_context do |config|
  config.include_context 'telegram/bot/integration/rack', telegram_bot: :rack
end
