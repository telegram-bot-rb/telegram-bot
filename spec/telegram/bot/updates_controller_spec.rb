RSpec.describe Telegram::Bot::UpdatesController do
  include_context 'telegram/bot/updates_controller'

  describe '#action_for_payload' do
    subject { controller.action_for_payload }

    def stub_payload(*fields)
      Hash[fields.map { |x| [x, double(x)] }]
    end

    context 'when payload is inline_query' do
      let(:payload_type) { 'inline_query' }
      let(:payload) { stub_payload(:id, :from, :location, :query, :offset) }
      it { should eq [payload_type, payload.values_at(:query, :offset)] }
    end

    context 'when payload is chosen_inline_result' do
      let(:payload_type) { 'chosen_inline_result' }
      let(:payload) { stub_payload(:result_id, :from, :location, :inline_message_id, :query) }
      it { should eq [payload_type, payload.values_at(:result_id, :query)] }
    end

    context 'when payload is callback_query' do
      let(:payload_type) { 'callback_query' }
      let(:payload) { stub_payload(:id, :from, :message, :inline_message_id, :data) }
      it { should eq [payload_type, payload.values_at(:data)] }
    end

    context 'when payload is poll_answer' do
      let(:payload_type) { 'poll_answer' }
      let(:payload) { stub_payload(:poll_id, :user, :option_ids) }
      it { should eq [payload_type, payload.values_at(:poll_id, :option_ids)] }
    end

    context 'when payload is not supported' do
      let(:payload_type) { '_unsupported_' }
      it { should eq [:unsupported_payload_type, []] }
    end

    custom_payload_types = %w[
      message
      edited_message
      channel_post
      edited_channel_post
      inline_query
      chosen_inline_result
      callback_query
      poll_answer
    ]
    (described_class::PAYLOAD_TYPES - custom_payload_types).each do |type|
      context "when payload is #{type}" do
        let(:payload_type) { type }
        it { should eq [payload_type, [payload]] }
      end
    end
  end

  context 'when `update` is a virtus model' do
    subject { controller }
    let(:update) { Telegram::Bot::Types::Update.new(super()) }
    %w[
      message
      inline_query
      chosen_inline_result
    ].each do |type|
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
    let(:args) { %i[arg1 arg2] }
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

      context 'when callback halts chain' do
        before do
          controller_class.prepend(Module.new do
            def hook
              super
              ActiveSupport::VERSION::MAJOR >= 5 ? throw(:abort) : false
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
          initial_update = deep_stringify message: {
            text: 'original message',
            from: double(:original_from),
            chat: double(:original_chat),
          }
          described_class.new(double(:other_bot), initial_update).
            tap { |x| x.send(:initialize, *controller_args) }
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
      let(:controller_args) { [bot, from: from, chat: chat] }
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

  describe '#chat' do
    subject { controller.chat }
    let(:payload_type) { :message }
    let(:payload) { {chat: 'test_value'} }
    it { should eq payload[:chat] }

    context 'when payload is not set' do
      let(:payload) {}
      it { should eq nil }
    end

    context 'when payload has no such field' do
      let(:payload) { {smth: 'other'} }
      it { should eq nil }

      context 'but has `message`' do
        let(:payload) { {message: message} }
        let(:message) { {text: 'Hello bot!'} }
        it { should eq nil }

        context 'with `chat` set' do
          let(:message) { super().merge(chat: 'test value') }
          it { should eq message[:chat] }
        end
      end
    end
  end

  describe '#from' do
    subject { controller.from }
    let(:payload_type) { :message }
    let(:payload) { {from: 'test_value'} }
    it { should eq payload[:from] }

    context 'when payload is not set' do
      let(:payload) {}
      it { should eq nil }
    end

    context 'when payload has no such field' do
      let(:payload) { {smth: 'other'} }
      it { should eq nil }
    end
  end
end
