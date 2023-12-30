# frozen_string_literal: true

RSpec.describe Telegram::Bot::UpdatesController::CallbackQueryContext do
  include_context 'telegram/bot/updates_controller'
  let(:controller_class) do
    described_class = self.described_class
    Class.new(Telegram::Bot::UpdatesController) do
      include described_class

      attr_accessor :filter_done

      before_action only: :ctx_2_callback_query do
        self.filter_done = true
      end

      def callback_query(data)
        [:no_context, data]
      end

      def ctx_1_callback_query(data)
        [:ctx_1, data]
      end

      def ctx_2_callback_query(data)
        [:ctx_2, data]
      end
    end
  end

  describe '#dispatch' do
    subject { -> { dispatch } }
    let(:payload_type) { :callback_query }
    let(:payload) { {data: data} }
    let(:data) { text }
    let(:text) { 'asd qwe zxc' }

    context 'when context is not set' do
      its(:call) { should eq [:no_context, text] }
      it { should_not change(controller, :filter_done) }
    end

    context 'when context is set' do
      let(:data) { "#{ctx}:#{text}" }

      context 'and valid' do
        let(:ctx) { 'ctx_1' }
        its(:call) { should eq [:ctx_1, text] }
        it { should_not change(controller, :filter_done) }

        context 'and context has callback' do
          let(:ctx) { 'ctx_2' }
          its(:call) { should eq [:ctx_2, text] }
          it { should change(controller, :filter_done) }
        end

        context 'and data has multiple colons' do
          let(:text) { super().tr(' ', ':') }
          its(:call) { should eq [:ctx_1, text] }
        end
      end

      context 'and invalid' do
        let(:ctx) { 'missing' }
        its(:call) { should eq [:no_context, data] }
      end
    end
  end
end
