require 'integration_helper'

RSpec.describe DefaultBotController, :telegram_bot, type: :request do
  describe '#start' do
    subject { -> { dispatch_command :start } }
    it { should respond_with_message 'from default' }
  end
end
