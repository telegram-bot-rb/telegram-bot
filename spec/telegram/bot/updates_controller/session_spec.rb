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

        def write!(text)
          session[:text] = text
        end

        def read!
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
      deep_stringify(message: {text: text, from: from})
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

  describe '.build_session' do
    subject { controller_class.build_session(key, *args) }
    let(:key) {}
    let(:args) { [] }
    it { expect { subject }.to raise_error(/session_store is not configured/) }

    shared_examples 'NullSessionHash when key is not present' do |store_proc|
      it { should be_instance_of(described_class::NullSessionHash) }

      context 'and key is present' do
        let(:key) { :test_key }
        it 'is valid SessionHash' do
          expect(subject).to be_instance_of(described_class::SessionHash)
          expect(subject.id).to eq key
          expect(subject.instance_variable_get(:@store)).to be(instance_exec(&store_proc))
        end
      end
    end

    context 'when store configured' do
      before { controller_class.session_store = nil }
      include_examples 'NullSessionHash when key is not present',
        -> { controller_class.session_store }
    end

    context 'when store is given' do
      let(:args) { [double(:store)] }
      include_examples 'NullSessionHash when key is not present', -> { args[0] }
    end
  end

  describe '.session_store=' do
    subject { ->(val) { controller_class.session_store = val } }
    it 'casts to AS::Cache' do
      expect { subject[:null_store] }.to change(controller_class, :session_store).
        to(instance_of(ActiveSupport::Cache::NullStore))
      expect { subject[nil] }.to change(controller_class, :session_store).
        to(instance_of(ActiveSupport::Cache::MemoryStore))
    end
  end
end
