require 'integration_helper'

RSpec.describe OtherBotController, telegram_bot: :rails do
  let(:bot) { Telegram.bots[:other] }
  describe '#start' do
    subject { -> { dispatch_command :start } }
    it { should respond_with_message 'from other' }
  end

  describe '#load_session' do
    subject { -> { dispatch_command :load_session } }
    it { should raise_error(/session_store is not configured/) }
  end
end
