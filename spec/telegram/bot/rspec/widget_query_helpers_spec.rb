# frozen_string_literal: true

require 'telegram/bot/rspec/integration/poller'

RSpec.describe 'Integration spec helpers', telegram_bot: :poller do
  let(:bot) { Telegram::Bot::ClientStub.new('token') }
  let(:controller_class) do
    Class.new(Telegram::Bot::UpdatesController) do
      include Telegram::Bot::UpdatesController::WidgetQueryContext

      def widget_query(data = nil, *)
        answer_widget_query "data: #{data}"
      end

      def silent_widget_query(*)
        answer_widget_query
      end

      def answer_and_edit_widget_query(data = nil, *)
        edit_message :widget_data, chat_data: "state: #{data}", extra: :param
        answer_widget_query "data: #{data}", extra: :param
      end
    end
  end

  describe '#widget_query', :widget_query do
    let(:data) { 'unknown:command' }
    it { should answer_widget_query("data: #{data}") }
    it { should answer_widget_query }
    it { should_not answer_widget_query('other data') }
    it { should_not edit_current_message(:widget_data) }
  end

  describe '#silent_widget_query', :widget_query do
    let(:data) { 'silent:' }
    it { should answer_widget_query }
    it { should_not answer_widget_query(/./) }
  end

  describe 'tag on the group with integration context', :widget_query, telegram_bot: :poller do
    let(:data) { 'silent:' }
    it { should answer_widget_query }
    it { expect(payload.keys).to eq %i[id from chat message_id data] }
  end

  describe '#answer_and_edit_widget_query', :widget_query do
    let(:data) { 'answer_and_edit:test:payload' }
    it do
      should answer_widget_query(/test:payload/, extra: :param).
        and edit_current_message(:widget_data, chat_data: /state: test/, extra: :param)
    end
  end
end
