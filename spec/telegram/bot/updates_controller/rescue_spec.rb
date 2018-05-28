RSpec.describe Telegram::Bot::UpdatesController::Rescue do
  include_context 'telegram/bot/updates_controller'

  describe '#process_action' do
    subject { -> { dispatch_message("/#{command} x y z") } }

    let(:controller_class) do
      Class.new(Telegram::Bot::UpdatesController) do
        rescue_from ArgumentError, with: -> { respond_with :message, text: 'Rescued' }

        def rescuable!(*)
          raise ArgumentError, 'rescuable'
        end

        def not_rescuable!(*)
          raise 'not_rescuable'
        end
      end
    end

    context 'when exception is rescued' do
      let(:command) { :rescuable }
      it { should respond_with_message 'Rescued' }
    end

    context 'when exception is not rescued' do
      let(:command) { :not_rescuable }
      it { should raise_error('not_rescuable') }
    end
  end
end
