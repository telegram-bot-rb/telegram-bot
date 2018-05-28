RSpec.describe Telegram::Bot::UpdatesController::MessageContext do
  include_context 'telegram/bot/updates_controller'
  let(:controller_class) do
    described_class = self.described_class
    Class.new(Telegram::Bot::UpdatesController) do
      include described_class

      attr_accessor :filter_done
      before_action only: :redirect do
        self.filter_done = true
      end

      attr_reader :callbacks_runs
      before_action { @callbacks_runs = (@callbacks_runs || 0) + 1 }

      def message(*args)
        [:no_context, *args]
      end

      context_handler :block do |*args|
        [:block_result, *args]
      end

      context_handler :redirect
      context_handler :other_redirect, :redirect

      def redirect(*args)
        [:method_result, *args]
      end

      def action!(*args)
        [:action_result, *args]
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

    context 'when context is handled by block' do
      before { session[:context] = :block }
      its(:call) { should eq [:block_result, *text.split] }
      it { should_not change(controller, :filter_done) }
      it { should change { session[:context] }.to nil }

      context 'when message has no text' do
        let(:payload) { {'audio' => {'file_id' => 123}} }
        its(:call) { should eq [:block_result] }
      end

      context 'when message has new command' do
        let(:text) { '/action a s d' }
        its(:call) { should eq [:action_result, 'a', 's', 'd'] }
        it { should change { session[:context] }.to nil }
      end
    end

    context 'when context is handled by short redirect' do
      before { session[:context] = :redirect }
      its(:call) { should eq [:method_result, *text.split] }
      it { should change(controller, :filter_done).to true }
      it { should change { session[:context] }.to nil }
      it { should change(controller, :callbacks_runs).to 1 }

      context 'when message has no text' do
        let(:payload) { {'audio' => {'file_id' => 123}} }
        its(:call) { should eq [:method_result] }
        it { should change(controller, :filter_done).to true }
        it { should change { session[:context] }.to nil }
      end
    end

    context 'when context is handled by custom redirect' do
      before { session[:context] = :other_redirect }
      its(:call) { should eq [:method_result, *text.split] }
      it { should change(controller, :filter_done).to true }
      it { should change { session[:context] }.to nil }
    end

    context 'when context is action`s name but not mapped' do
      before { session[:context] = :action }
      its(:call) { should eq [:no_context, payload] }
      it { should_not change(controller, :filter_done) }
      it { should change { session[:context] }.to nil }
    end

    context 'when context_to_action is true' do
      before { controller_class.context_to_action! }

      context 'when context is not set' do
        its(:call) { should eq [:no_context, payload] }
        it { should_not change(controller, :filter_done) }
        it { should_not change { session[:context] } }
      end

      context 'when context is action`s name but not mapped' do
        before { session[:context] = :action! }
        its(:call) { should eq [:action_result, *text.split] }
        it { should_not change(controller, :filter_done) }
        it { should change { session[:context] }.to nil }
      end

      context 'when context is invalid' do
        before { session[:context] = :invalid }
        it 'raises error and clears context' do
          expect do
            should raise_error AbstractController::ActionNotFound
          end.to change { session[:context] }.to nil
        end
      end

      context 'when context is private method`s name' do
        before { session[:context] = :not_action }
        it 'raises error and clears context' do
          expect do
            should raise_error AbstractController::ActionNotFound
          end.to change { session[:context] }.to nil
        end
      end
    end
  end
end
