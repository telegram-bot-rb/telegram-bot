RSpec.describe Telegram::Bot::UpdatesController::Translation do
  def self.stub_translations(translations)
    around do |ex|
      backend = I18n.backend
      I18n.backend = I18n::Backend::Simple.new
      begin
        I18n.backend.store_translations 'en', telegram: {webhooks: translations}
        ex.run
      ensure
        I18n.backend = backend
      end
    end
  end
  let(:result) { double(:result) }

  describe '#translate' do
    stub_translations(
      start: {
        hello: 'Hello from start!',
        hi: 'Hi %{name} from start', # rubocop:disable Style/FormatStringToken
      },
    )

    let(:controller) do
      double(
        controller_path: 'telegram/webhooks',
        action_name: 'start!',
      ).tap { |x| x.extend(described_class) }
    end

    it 'uses action_name without ! for lazy translations' do
      expect(I18n).to receive(:translate).with('telegram.webhooks.start.hello',
        default: [:'telegram.webhooks.hello'],
      ) { result }
      expect(controller.t('.hello')).to eq(result)

      expect(I18n).to receive(:translate).with('telegram.webhooks.start.hi',
        default: [:'telegram.webhooks.hi'],
        name: 'Dude',
      ) { result }
      expect(controller.t('.hi', name: 'Dude')).to eq(result)
    end

    it 'translates' do
      expect(controller.t('.hello')).to eq('Hello from start!')
      expect(controller.t('.hi', name: 'Dude')).to eq('Hi Dude from start')
    end
  end

  describe described_class::ClassMethods do
    stub_translations(
      hello: 'Hello!',
      hi: 'Hi %{name}', # rubocop:disable Style/FormatStringToken
    )

    describe '#translate' do
      let(:controller_class) do
        double(controller_path: 'telegram/webhooks').
          tap { |x| x.extend(described_class) }
      end

      it 'uses controller_path for lazy translations' do
        expect(I18n).to receive(:translate) do |*args, **kwargs|
          # not using .with to support ruby 2.x and 3.x
          expect([*args, kwargs]).to eq(['telegram.webhooks.hello', {}])
          result
        end
        expect(controller_class.t('.hello')).to eq(result)

        expect(I18n).to receive(:translate).with('telegram.webhooks.hi', name: 'Dude') { result }
        expect(controller_class.t('.hi', name: 'Dude')).to eq(result)
      end

      it 'translates' do
        expect(controller_class.t('.hello')).to eq('Hello!')
        expect(controller_class.t('.hi', name: 'Dude')).to eq('Hi Dude')
      end
    end
  end
end
