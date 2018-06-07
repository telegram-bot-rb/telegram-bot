RSpec.describe Telegram::Bot::UpdatesController::Translation do
  describe '#translate' do
    let(:controller) do
      double(
        controller_path: 'telegram/webhooks',
        action_name: 'start!',
      ).tap { |x| x.extend(described_class) }
    end

    it 'uses action_name without ! for lazy translations' do
      expect(I18n).to receive(:translate).with('telegram.webhooks.start.hello',
        default: [:'telegram.webhooks.hello'],
      )
      controller.t('.hello')
    end
  end
end
