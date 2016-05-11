RSpec.describe Telegram::Bot::UpdatesController do
  include_context 'telegram/bot/updates_controller'
  let(:other_bot_name) { 'other_bot' }

  describe '.action_for_command' do
    subject { ->(*args) { described_class.action_for_command(*args) } }

    def assert_subject(input, expected)
      expect(subject.call input).to eq expected
    end

    it 'bypasses and downcases not conflictint commands' do
      assert_subject 'test', 'test'
      assert_subject 'TeSt', 'test'
      assert_subject '_Te1St', '_te1st'
    end

    it 'adds _on to conflicting commands' do
      described_class::PAYLOAD_TYPES.each do |x|
        assert_subject x, "on_#{x}"
        assert_subject x.upcase, "on_#{x}"
      end
      assert_subject '1TeSt', 'on_1test'
    end
  end

  describe '.command_from_text' do
    subject { ->(*args) { described_class.command_from_text(*args) } }

    def assert_subject(input, cmd, *args)
      expected = cmd ? [cmd, args] : cmd
      expect(subject.call(*input)).to eq expected
    end

    let(:max_cmd_size) { 32 }
    let(:long_cmd) { 'a' * (max_cmd_size - 1) }
    let(:too_long_cmd) { 'a' * max_cmd_size }

    it 'works for simple commands' do
      assert_subject '/test', 'test'
      assert_subject '/tE_2_St', 'tE_2_St'
      assert_subject '/123', '123'
      assert_subject "/#{long_cmd}", long_cmd
    end

    it 'works for simple messages' do
      assert_subject 'text', nil
      assert_subject ' ', nil
      assert_subject ' text', nil
      assert_subject ' 1', nil
      assert_subject ' /text', nil
      assert_subject '/te-xt', nil
      assert_subject 'text /cmd ', nil
      assert_subject "/#{too_long_cmd}", nil
    end

    it 'works for mentioned commands' do
      assert_subject ['/test@bot', 'bot'], 'test'
      assert_subject ['/test@otherbot', 'bot'], nil
      assert_subject ['/test@Bot', 'bot'], nil
      assert_subject '/test@bot', nil
      assert_subject ['/test@bot', true], 'test'
      assert_subject ['/test@otherbot', true], 'test'
    end

    it 'works for commands with args' do
      assert_subject '/test arg', 'test', 'arg'
      assert_subject '/test  arg  1  2', 'test', 'arg', '1', '2'
      assert_subject ['/test@bot arg', 'bot'], 'test', 'arg'
      assert_subject ['/test@otherbot arg', 'bot'], nil
      assert_subject '/test@bot arg', nil
    end

    it 'works for commands with multiline args' do
      assert_subject "/test arg\nother", 'test', 'arg', 'other'
      assert_subject "/test one\ntwo\n\nthree", 'test', 'one', 'two', 'three'
    end
  end

  describe '#action_for_payload' do
    subject { controller.action_for_payload }

    (described_class::PAYLOAD_TYPES - %w(message)).each do |type|
      context "when payload is #{type}" do
        let(:payload_type) { type }
        it { should eq [false, type, [payload]] }
      end
    end

    context 'when payload is message' do
      let(:payload_type) { 'message' }
      let(:payload) { {'text' => text} }
      let(:text) { 'test' }

      it { should eq [false, payload_type, [payload]] }

      context 'with command' do
        let(:text) { "/test#{"@#{mention}" if mention} arg 1 2" }
        let(:mention) {}
        it { should eq [true, 'test', %w(arg 1 2)] }

        context 'with mention' do
          let(:mention) { bot.username }
          it { should eq [true, 'test', %w(arg 1 2)] }
        end

        context 'with mention for other bot' do
          let(:mention) { other_bot_name }
          it { should eq [false, 'message', [payload]] }
        end
      end

      context 'without text' do
        let(:payload) { {'audio' => {'file_id' => 123}} }
        it { should eq [false, payload_type, [payload]] }
      end
    end
  end

  context 'when `update` is a virtus model' do
    subject { controller }
    let(:update) { Telegram::Bot::Types::Update.new(super()) }
    %w(
      message
      inline_query
      chosen_inline_result
    ).each do |type|
      context "with #{type}" do
        type_class = Telegram::Bot::Types.const_get(type.camelize)
        let(:payload_type) { type }
        let(:payload) { {} }
        its(:payload_type) { should eq payload_type }
        its(:payload) { should be_instance_of type_class }
      end
    end
  end

  describe '#bot_username' do
    subject { controller.bot_username }

    context 'when bot is not set' do
      let(:bot) {}
      it { should eq nil }
    end

    context 'when bot is set' do
      let(:bot) { double(username: double(:username)) }
      it { should eq bot.username }
    end
  end

  describe '#process' do
    subject { -> { controller.process(:action, *args) } }
    let(:args) { [:arg1, :arg2] }
    let(:controller_class) do
      Class.new(described_class) do
        attr_reader :acted, :hooked

        def action(*args)
          @acted = true
          [from, chat, args]
        end
      end
    end

    context 'when action is protected' do
      before { controller_class.send :protected, :action }
      its(:call) { should eq nil }

      context 'when action_missing defined' do
        before do
          controller.class_eval do
            protected

            def action_missing(*args)
              args
            end
          end
        end

        its(:call) { should eq ['action', *args] }
      end
    end

    context 'when callbacks are defined' do
      before do
        controller_class.class_eval do
          before_action :hook, only: :action
          attr_reader :hooked

          private

          def hook
            @hooked = true
          end
        end
      end

      it { should change(controller, :hooked).to true }
      it { should change(controller, :acted).to true }
      its(:call) { should eq [nil, nil, args] }

      context 'when callback returns false' do
        before do
          controller_class.prepend(Module.new do
            def hook
              super
              false
            end
          end)
        end

        it { should change(controller, :hooked).to true }
        it { should_not change(controller, :acted).from nil }
        its(:call) { should eq false }
      end
    end

    context 'when initialized without update' do
      let(:controller) { controller_class.new(bot, from: from, chat: chat) }
      let(:from) { {'id' => 'user_id'} }
      let(:chat) { {'id' => 'chat_id'} }
      its(:call) { should eq [from, chat, args] }
    end
  end

  describe '#initialize' do
    subject { controller }
    let(:payload_type) { 'message' }
    let(:payload) { deep_stringify(chat: chat, from: from) }
    let(:chat) { double(:chat) }
    let(:from) { double(:from) }

    def self.with_reinitialize(&block)
      instance_eval(&block)
      context 'when re-initialized' do
        let(:controller) do
          described_class.new(double(:other_bot), build_update(:message,
            text: 'original message',
            from: double(:original_from),
            chat: double(:original_chat),
          )).tap { |x| x.send(:initialize, bot, update) }
        end
        instance_eval(&block)
      end
    end

    context 'when update is given' do
      with_reinitialize do
        its(:bot) { should eq bot }
        its(:update) { should eq update }
        its(:payload) { should eq payload }
        its(:payload_type) { should eq payload_type }
        its(:from) { should eq from }
        its(:chat) { should eq chat }
      end
    end

    context 'when options hash is given' do
      let(:update) { {from: from, chat: chat} }
      with_reinitialize do
        its(:bot) { should eq bot }
        its(:update) { should eq nil }
        its(:payload) { should eq nil }
        its(:payload_type) { should eq nil }
        its(:from) { should eq from }
        its(:chat) { should eq chat }
      end
    end
  end

  describe '#reply_with' do
    subject { controller.reply_with type, params }
    let(:params) { {arg: 1, 'other_arg' => 2} }
    let(:type) { :photo }
    let(:result) { double(:result) }
    let(:payload_type) { :message }
    let(:payload) { {message_id: double(:message_id)} }
    let(:chat) { {'id' => double(:chat_id)} }

    it 'sets chat_id & reply_to_message' do
      expect(controller).to receive(:chat) { chat }
      expect(bot).to receive("send_#{type}").with(params.merge(
        chat_id: chat['id'],
        reply_to_message: payload[:message_id],
      )) { result }
      should eq result
    end

    context 'when chat is missing' do
      let(:payload_type) { :some_type }
      it { expect { subject }.to raise_error(/chat/) }
    end

    context 'when update is not set' do
      let(:update) { {chat: chat} }
      it 'sets chat_id & reply_to_message' do
        expect(bot).to receive("send_#{type}").with(params.merge(
          chat_id: chat['id'],
          reply_to_message: nil,
        )) { result }
        should eq result
      end
    end
  end
end
