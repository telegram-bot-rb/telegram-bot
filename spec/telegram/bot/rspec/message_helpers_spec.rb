require 'telegram/bot/rspec/integration/poller'

RSpec.describe 'Integration: message helpers', telegram_bot: :poller do
  describe '#default_message_options' do
    subject { default_message_options }
    it { should eq from: {id: from_id}, chat: {id: chat_id} }
  end

  describe '#dispatch_message' do
    subject { -> { dispatch_message text, options } }
    let(:text) { '/start asd qwe' }
    let(:options) { {} }
    let(:result) { double(:result) }

    it 'invokes dispatch' do
      expect(self).to receive(:dispatch).with(
        message: hash_including(default_message_options.merge(
          text: text,
        )),
      ) { result }
      expect(subject.call).to eq result
    end

    context 'with options' do
      let(:options) { {option: 1} }
      it 'invokes dispatch' do
        expect(self).to receive(:dispatch).with(
          message: hash_including(default_message_options.merge(
            text: text,
          ).merge(options)),
        ) { result }
        expect(subject.call).to eq result
      end
    end
  end

  describe '#dispatch_command' do
    subject { -> { dispatch_command :start, *args } }
    let(:args) { [] }
    let(:result) { double(:result) }

    it 'invokes dispatch' do
      expect(self).to receive(:dispatch).with(
        message: hash_including(default_message_options.merge(
          text: '/start',
        )),
      ) { result }
      expect(subject.call).to eq result
    end

    context 'with args & options' do
      let(:args) { [*params, options] }
      let(:params) { %w[qwe asd] }
      let(:options) { {option: 1} }
      it 'invokes dispatch' do
        expect(self).to receive(:dispatch).with(
          message: hash_including(default_message_options.merge(
            text: "/start #{params.join(' ')}",
          ).merge(options)),
        ) { result }
        expect(subject.call).to eq result
      end
    end
  end
end

# Old specs
RSpec.describe 'Integration: message helpers', telegram_bot: :poller do
  let(:bot) { Telegram::Bot::ClientStub.new('token') }
  let(:controller_class) do
    Class.new(Telegram::Bot::UpdatesController) do
      def start!(*args)
        respond_with :message, text: "Start: #{args.inspect}, option: #{payload['option']}"
      end
    end
  end

  describe '#default_message_options' do
    subject { default_message_options }
    it { should eq from: {id: from_id}, chat: {id: chat_id} }
  end

  describe '#dispatch_message' do
    subject { -> { dispatch_message "/start #{args.join ' '}", options } }
    let(:args) { %w[asd qwe] }
    let(:options) { {} }
    it { should respond_with_message "Start: #{args.inspect}, option: " }

    context 'with options' do
      let(:options) { {option: 1} }
      it { should respond_with_message "Start: #{args.inspect}, option: 1" }

      context 'and chat_id is not set' do
        let(:options) { super().merge(chat: nil) }
        it { should raise_error(/chat is not present/) }
      end
    end
  end

  describe '#dispatch_command' do
    subject { -> { dispatch_command :start, *args } }
    let(:args) { [] }
    it { should respond_with_message "Start: #{args.inspect}, option: " }

    context 'with args' do
      let(:args) { %w[asd qwe] }
      it { should respond_with_message "Start: #{args.inspect}, option: " }
    end

    context 'with options' do
      let(:args) { ['asd', 'qwe', option: 1] }
      it { should respond_with_message "Start: #{args[0...-1].inspect}, option: 1" }
    end
  end
end
