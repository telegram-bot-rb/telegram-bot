RSpec.describe Telegram::Bot::UpdatesController do
  include_context 'telegram/bot/updates_controller'

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
