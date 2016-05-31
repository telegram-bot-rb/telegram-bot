RSpec.describe Telegram::Bot::UpdatesController::Session do
  include_context 'telegram/bot/updates_controller'
  let(:controller_class) do
    described_class = self.described_class
    Class.new(Telegram::Bot::UpdatesController) do
      include described_class
    end
  end

  describe '.action_methods' do
    subject { controller_class.action_methods }
    it { should be_empty }
  end

  describe '.dispatch' do
    subject { ->(*args) { controller_class.dispatch(*args) } }
    let(:other_bot) { double(username: 'otherBot') }
    before do
      controller_class.class_eval do
        self.session_store = :memory_store

        def write(text)
          session[:text] = text
        end

        def read
          session[:text]
        end

        def action_missing(*)
          [:action_missing, session[:text]].tap do
            session[:text] = 'test'
          end
        end
      end
    end

    def build_message(text, from)
      {'message' => {'text' => text, 'from' => from.stringify_keys}}
    end

    it 'stores session between requests' do
      subject.call(bot, build_message('/write test', id: 1))
      expect(subject.call(bot, build_message('/read', id: 1))).to eq 'test'
      expect(subject.call(bot, build_message('/read', id: 2))).to eq nil
      expect(subject.call(other_bot, build_message('/read', id: 1))).to eq nil
    end

    context 'payload is not supported' do
      let(:payload_type) { '_unsupported_' }
      it 'provides empty session' do
        2.times { expect(subject.call(bot)).to eq [:action_missing, nil] }
        expect(subject.call(other_bot)).to eq [:action_missing, nil]
      end
    end
  end
end
