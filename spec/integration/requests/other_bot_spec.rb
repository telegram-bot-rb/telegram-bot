require 'integration_helper'

RSpec.describe OtherBotController, :telegram_bot, type: :request do
  let(:bot) { Telegram.bots[:other] }
  describe '#start' do
    subject { -> { dispatch_command :start } }
    it { should respond_with_message 'from other' }
  end
end
