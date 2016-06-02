require 'rack/mock'

RSpec.describe Telegram::Bot::Middleware do
  let(:instance) { described_class.new bot, controller }
  let(:bot) { double(:bot) }
  let(:controller) { double(:controller, dispatch: :dispatch_result) }

  describe '#call' do
    subject { instance.call(env) }

    if ActiveSupport.gem_version >= Gem::Version.new('5.0.0.rc1')
      let(:env) do
        Rack::MockRequest.env_for('/',
                                  method: :post,
                                  input: '{"valid": "json"}',
                                  'CONTENT_TYPE' => 'application/json'
                                 )
      end

      it 'calls dispatch on controller' do
        expect(controller).to receive(:dispatch).with(bot, hash_including(valid: 'json'))
        subject
      end
    else
      let(:json_body) { double(:json_body) }
      let(:env) { {'action_dispatch.request.request_parameters' => json_body} }

      it 'calls dispatch on controller' do
        expect(controller).to receive(:dispatch).with(bot, json_body)
        subject
      end
    end

    it { should eq [200, {}, ['']] }
  end
end
