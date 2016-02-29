RSpec.describe Telegram::Bot::Middleware do
  let(:instance) { described_class.new bot, controller }
  let(:bot) { double(:bot) }
  let(:controller) { double(:controller, dispatch: :dispatch_result) }

  describe '#call' do
    subject { instance.call(env) }
    let(:env) { {'action_dispatch.request.request_parameters' => json_body} }
    let(:json_body) { double(:json_body) }

    it 'calls dispatch on controller' do
      expect(controller).to receive(:dispatch).with(bot, json_body)
      subject
    end

    it { should eq [200, {}, ['']] }
  end
end
