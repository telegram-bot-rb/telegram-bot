RSpec.describe Telegram::Bot::UpdatesController::MessageContext do
  include_context 'telegram/bot/updates_controller'
  let(:controller_class) do
    described_class = self.described_class
    Class.new(Telegram::Bot::UpdatesController) do
      include described_class

      attr_accessor :filter_done
      before_action only: :context_with_filter do
        self.filter_done = true
      end

      attr_reader :callbacks_runs
      before_action { @callbacks_runs = (@callbacks_runs || 0) + 1 }

      def message(*args)
        [:no_context, *args]
      end

      def handler_method(*args)
        [:method_result_1, *args]
      end

      def context_with_filter(*args)
        [:method_result_2, *args]
      end

      def action!(*args)
        [:command_result, *args]
      end

      private

      def not_action
        raise 'Should not be called!'
      end
    end
  end

  describe '#message' do
    subject { -> { dispatch } }
    let(:payload_type) { :message }
    let(:payload) { {'text' => text} }
    let(:text) { 'asd qwe zxc' }

    context 'when context is not set' do
      its(:call) { should eq [:no_context, payload] }
      it { should_not change(controller, :filter_done) }
      it { should_not change { session[:context] } }
    end

    context 'when context is handled by handler_method' do
      before { session[:context] = :handler_method }
      its(:call) { should eq [:method_result_1, *text.split] }
      it { should_not change(controller, :filter_done) }
      it { should change { session[:context] }.to nil }

      context 'when message has no text' do
        let(:payload) { {'audio' => {'file_id' => 123}} }
        its(:call) { should eq [:method_result_1] }
      end

      context 'when message has new command' do
        let(:text) { '/action a s d' }
        its(:call) { should eq [:command_result, 'a', 's', 'd'] }
        it { should change { session[:context] }.to nil }
      end
    end

    context 'when context is handled by short context_with_filter' do
      before { session[:context] = :context_with_filter }
      its(:call) { should eq [:method_result_2, *text.split] }
      it { should change(controller, :filter_done).to true }
      it { should change { session[:context] }.to nil }
      it { should change(controller, :callbacks_runs).to 1 }

      context 'when message has no text' do
        let(:payload) { {'audio' => {'file_id' => 123}} }
        its(:call) { should eq [:method_result_2] }
        it { should change(controller, :filter_done).to true }
        it { should change { session[:context] }.to nil }
      end
    end

    context 'when context is command-action`s name' do
      before { session[:context] = :action! }
      its(:call) { should eq [:command_result, *text.split] }
      it { should_not change(controller, :filter_done) }
      it { should change { session[:context] }.to nil }
    end

    context 'when context is not an action`s name' do
      before { session[:context] = :not_action }
      it do
        should raise_error(AbstractController::ActionNotFound).
          and change { session[:context] }.to nil
      end
    end

    context 'when context is invalid name' do
      before { session[:context] = :invalid }
      it do
        should raise_error(AbstractController::ActionNotFound).
          and change { session[:context] }.to nil
      end
    end
  end
end
