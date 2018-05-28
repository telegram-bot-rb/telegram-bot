RSpec.describe Telegram::Bot::UpdatesController::Commands do
  describe '#action_for_command' do
    subject { ->(*args) { object.action_for_command(*args) } }
    let(:object) { Object.new.tap { |x| x.extend described_class } }

    def assert_subject(input, expected)
      expect(subject.call input).to eq expected
    end

    it 'bypasses and downcases not conflictint commands' do
      assert_subject 'test', 'test!'
      assert_subject 'TeSt', 'test!'
      assert_subject '_Te1St', '_te1st!'
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
    include_context 'telegram/bot/updates_controller'
    let(:controller_class) { Telegram::Bot::UpdatesController }
    subject { controller.action_for_payload }

    %w[message channel_post].each do |type|
      context "when payload is edited_#{type}" do
        let(:payload_type) { "edited_#{type}" }
        it { should eq [payload_type, [payload]] }
      end

      context 'when payload is message' do
        let(:payload_type) { type }
        let(:payload) { {'text' => text} }
        let(:text) { 'test' }

        it { should eq [payload_type, [payload]] }

        context 'with command' do
          let(:text) { "/test#{"@#{mention}" if mention} arg 1 2" }
          let(:mention) {}
          it { should eq [['test!', type: :command, command: 'test'], %w[arg 1 2]] }

          context 'with mention' do
            let(:mention) { bot.username }
            it { should eq [['test!', type: :command, command: 'test'], %w[arg 1 2]] }
          end

          context 'with mention for other bot' do
            let(:mention) { 'other_bot_name' }
            it { should eq [payload_type, [payload]] }
          end
        end

        context 'without text' do
          let(:payload) { {'audio' => {'file_id' => 123}} }
          it { should eq [payload_type, [payload]] }
        end
      end
    end
  end
end
