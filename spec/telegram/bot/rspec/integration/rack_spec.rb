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

  describe '#dispatch' do
    it 'provides webhook_request' do
      expect(controller_class).to receive(:dispatch).
        with(bot, hash_including('message'), instance_of(ActionDispatch::Request)).
        and_call_original
      dispatch_message :test
    end
  end
end
