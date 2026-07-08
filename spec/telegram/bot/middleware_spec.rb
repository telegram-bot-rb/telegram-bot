# frozen_string_literal: true

require 'rack/mock'

RSpec.describe Telegram::Bot::Middleware do
  let(:instance) { described_class.new bot, controller }
  let(:bot) { double(:bot) }
  let(:controller) { double(:controller, dispatch: nil) }
  let(:webhook_response) { nil }

  describe '#call' do
    subject { instance.call(env) }
    let(:update) { {'message' => {'id' => 1}} }
    let(:env) do
      Rack::MockRequest.env_for('/',
        method: :post,
        input: JSON.dump(update),
        'CONTENT_TYPE' => 'application/json',
      )
    end

    require 'action_pack/version'
    if ActionPack::VERSION::MAJOR < 5
      # Before Rails 5, params are parsed in middleware.
      # In Rails 5, they are parsed in Request#request_parameters.
      let(:instance) { ActionDispatch::ParamsParser.new(super()) }
    end

    before do
      # `dispatch` claims the webhook response, when there's one, by setting it
      # on the very same request object it received - same as the real controller.
      allow(controller).to receive(:dispatch) do |_bot, _update, request|
        key = Telegram::Bot::UpdatesController::WEBHOOK_RESPONSE_ENV_KEY
        request.set_header(key, webhook_response)
      end
    end

    it 'calls dispatch on controller' do
      expect(controller).to receive(:dispatch).
        with(bot, update, instance_of(ActionDispatch::Request))
      subject
    end

    it { should eq [200, {}, ['']] }

    context 'when controller claims the webhook response' do
      let(:webhook_response) { '{"method":"sendMessage","text":"hi"}' }
      it { should eq [200, {'Content-Type' => 'application/json'}, [webhook_response]] }
    end
  end
end
