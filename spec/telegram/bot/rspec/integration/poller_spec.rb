require 'telegram/bot/rspec/integration/poller'

RSpec.describe 'Poller integration spec', telegram_bot: :poller do
  include_examples 'shared integration examples'

  describe '#dispatch' do
    it 'doesn`t provide webhook_request' do
      expect(controller_class).to receive(:dispatch).
        with(bot, hash_including('message')).
        and_call_original
      dispatch_message :test
    end
  end
end
