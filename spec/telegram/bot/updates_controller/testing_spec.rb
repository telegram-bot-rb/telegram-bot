require 'action_dispatch'

RSpec.describe Telegram::Bot::UpdatesController::Testing do
  include_context 'telegram/bot/updates_controller'
  let(:controller_class) do
    Class.new(Telegram::Bot::UpdatesController) do
      attr_accessor :ivar
    end
  end

  describe '#recycle!' do
    subject { -> { controller.recycle!(full) } }
    before do
      controller.ivar = :ival
      session[:key] = 'sval'
    end
    let(:full) {}

    it { should_not change(controller, :ivar).from :ival }
    it { should_not change { controller.send(:session)[:key] }.from 'sval' }

    context 'when full is true' do
      let(:full) { true }
      it { should change(controller, :ivar).from(:ival).to nil }
      it { should change { controller.instance_variable_defined?(:@ivar) }.to false }
      it { should_not change { controller.send(:session)[:key] }.from 'sval' }
    end
  end

  describe '#dispatch' do
    it 'doesn`t provide webhook_request' do
      dispatch
      expect(controller.webhook_request).to eq nil
    end

    context 'when webhook_request is set' do
      let(:webhook_request) { ActionDispatch::Request.new({}) }
      it 'passes it to controller' do
        dispatch
        expect(controller.webhook_request).to eq webhook_request
      end
    end

    context 'when webhook_request is given' do
      it 'passes it to controller' do
        webhook_request = ::ActionDispatch::Request.new({})
        dispatch(update, bot, webhook_request)
        expect(controller.webhook_request).to eq webhook_request
      end
    end
  end
end
