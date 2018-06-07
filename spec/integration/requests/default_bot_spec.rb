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
end
