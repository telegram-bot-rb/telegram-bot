require 'integration_helper'

RSpec.describe NamedBotController, telegram_bot: :rails do
  let(:bot) { Telegram.bots[:named] }
  describe '#start' do
    subject { -> { dispatch_command :start } }
    it { should respond_with_message 'from named' }
  end
end
