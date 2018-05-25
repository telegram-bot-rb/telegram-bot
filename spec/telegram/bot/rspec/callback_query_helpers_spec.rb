require 'telegram/bot/rspec/integration/poller'

RSpec.describe 'Integration spec helpers', telegram_bot: :poller do
  let(:bot) { Telegram::Bot::ClientStub.new('token') }
  let(:controller_class) do
    Class.new(Telegram::Bot::UpdatesController) do
      include Telegram::Bot::UpdatesController::CallbackQueryContext

      def callback_query(data = nil, *)
        answer_callback_query "data: #{data}"
      end

      def context_callback_query(data = nil, *)
        answer_callback_query "data: #{data}", extra: :param
      end

      def answer_and_edit_callback_query(data = nil, *)
        answer_callback_query "data: #{data}"
        edit_message :text, text: 'edited-text', extra: :param
      end
    end
  end

  describe '#callback_query', :callback_query do
    let(:data) { 'unknown:command' }
    it { should answer_callback_query("data: #{data}") }
  end

  describe '#context_callback_query', :callback_query do
    let(:data) { 'context:test:payload' }
    it { should answer_callback_query('data: test:payload', extra: :param) }
    it { should_not edit_current_message(:text) }
  end

  describe '#answer_and_edit_callback_query', :callback_query do
    let(:data) { 'answer_and_edit:test:payload' }
    it do
      should answer_callback_query(/test:payload/).
        and edit_current_message(:text, text: /edited/, extra: :param)
    end
  end
end
