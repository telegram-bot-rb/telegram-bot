require 'integration_helper'

RSpec.describe DefaultBotController, telegram_bot: :rails do
  describe '#start' do
    subject { -> { dispatch_command :start } }
    it { should respond_with_message 'from default' }
  end

  describe '#load_session' do
    subject { -> { dispatch_command :load_session } }
    it { should_not raise_error }
  end

  describe '#dispatch' do
    it 'provides webhook_request' do
      expect(described_class).to receive(:dispatch).
        with(bot, hash_including('message'), instance_of(ActionDispatch::Request)).
        and_call_original
      dispatch_message :test
    end
  end
end
