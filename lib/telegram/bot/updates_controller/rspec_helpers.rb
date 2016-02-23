RSpec.shared_context 'telegram/bot/updates_controller' do
  let(:instance) { described_class.new(bot, update) }
  let(:update) { {payload_type => payload} }
  let(:payload_type) { 'some_type' }
  let(:payload) { double(:payload) }
  let(:bot) { double(username: bot_name) }
  let(:bot_name) { 'bot' }
end
