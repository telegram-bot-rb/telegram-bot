require 'rack/mock'

RSpec.describe Telegram::Bot::Middleware do
  let(:instance) { described_class.new bot, controller }
  let(:bot) { double(:bot) }
  let(:controller) { double(:controller, dispatch: :dispatch_result) }

  describe '#call' do
    subject { instance.call(env) }
    let(:update) { {'message' => {'id' => 1}} }
    let(:env) do
      Rack::MockRequest.env_for('/',
        method: :post,
        input:  JSON.dump(update),
        'CONTENT_TYPE' => 'application/json',
      )
    end

    require 'action_pack/version'
    if ActionPack::VERSION::MAJOR < 5
      # Before Rails 5, params are parsed in middleware.
      # In Rails 5, they are parsed in Request#request_parameters.
      let(:instance) { ActionDispatch::ParamsParser.new(super()) }
    end

    it 'calls dispatch on controller' do
      expect(controller).to receive(:dispatch).
        with(bot, update, instance_of(ActionDispatch::Request))
      subject
    end

    it { should eq [200, {}, ['']] }
  end
end
