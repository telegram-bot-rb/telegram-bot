require 'telegram/bot/rspec/integration/rack'

RSpec.describe 'Rack integration spec', telegram_bot: :rack do
  include_examples 'shared integration examples'
  let(:request_path) { '/bot' }
  let(:app) do
    path = request_path
    bot_app = Telegram::Bot::Middleware.new(bot, controller_class)
    app = Rack::Builder.new do
      map(path) { run bot_app }
      run ->(env) { raise "Route is not mapped: #{env['PATH_INFO']}" }
    end
    if ActionPack::VERSION::MAJOR >= 5
      app
    else
      require 'action_dispatch/middleware/params_parser'
      ActionDispatch::ParamsParser.new(app)
    end
  end
end
