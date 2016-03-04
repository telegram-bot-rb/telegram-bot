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
end
