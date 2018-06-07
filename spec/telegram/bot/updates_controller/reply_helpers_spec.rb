RSpec.describe Telegram::Bot::UpdatesController do
  include_context 'telegram/bot/updates_controller'
  let(:params) { {arg: 1, 'other_arg' => 2} }
  let(:respond_type) { :photo }
  let(:result) { double(:result) }
  let(:payload_type) { :message }
  let(:payload) { {message_id: double(:message_id), chat: chat} }
  let(:chat) { {id: double(:chat_id)} }

  shared_examples 'missing chat' do
    context 'when chat is missing' do
      let(:payload_type) { :some_type }
      it { expect { subject }.to raise_error(/chat/) }
    end
  end

  describe '#respond_with' do
    subject { controller.respond_with respond_type, params }
    include_examples 'missing chat'

    it 'sets chat_id & reply_to_message_id' do
      expect(bot).to receive("send_#{respond_type}").
        with(params.merge(chat_id: chat[:id])) { result }
      should eq result
    end
  end

  describe '#reply_with' do
    subject { controller.reply_with respond_type, params }
    include_examples 'missing chat'

    it 'sets chat_id & reply_to_message_id' do
      expect(bot).to receive("send_#{respond_type}").with(params.merge(
        chat_id: chat[:id],
        reply_to_message_id: payload[:message_id],
      )) { result }
      should eq result
    end

    context 'when update is not set' do
      let(:controller_args) { [bot, chat: deep_stringify(chat)] }
      it 'sets chat_id' do
        expect(bot).to receive("send_#{respond_type}").
          with(params.merge(chat_id: chat[:id])) { result }
        should eq result
      end
    end
  end

  describe '#edit_message' do
    subject { controller.edit_message(type, params) }
    let(:type) { :reply_markup }

    it { expect { subject }.to raise_error(/Can not edit message without/) }

    context 'when inline_message_id is present' do
      let(:payload) { {inline_message_id: double(:message_id)} }
      it 'sets inline_message_id' do
        expect(bot).to receive("edit_message_#{type}").with(params.merge(
          inline_message_id: payload[:inline_message_id],
        )) { result }
        should eq result
      end
    end

    context 'when message is present' do
      let(:payload) { {message: super().merge(chat: chat)} }
      it 'sets chat_id & message_id' do
        expect(bot).to receive("edit_message_#{type}").with(params.merge(
          message_id: payload[:message][:message_id],
          chat_id: payload[:message][:chat][:id],
        )) { result }
        should eq result
      end
    end
  end
end
