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

  describe described_class::ClassMethods do
    describe '#translate' do
      let(:controller_class) do
        double(controller_path: 'telegram/webhooks').
          tap { |x| x.extend(described_class) }
      end

      it 'uses controller_path for lazy translations' do
        expect(I18n).to receive(:translate).with('telegram.webhooks.hello', {})
        controller_class.t('.hello')
      end
    end
  end
end
