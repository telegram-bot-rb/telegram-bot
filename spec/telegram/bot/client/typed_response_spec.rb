RSpec.describe Telegram::Bot::Client::TypedResponse do
  let(:bot) { Telegram::Bot::Client.new('token').tap { |x| x.extend described_class } }

  describe '#get_me' do
    subject { bot.get_me }
    before { expect(bot).to receive(:request).with('getMe') { response } }
    let(:response) { {'ok' => true, 'result' => {'id' => user_id}} }
    let(:user_id) { 123 }
    it { should be_instance_of Telegram::Bot::Types::User }
    its(:id) { should eq user_id }

    context 'on error' do
      let(:response) { raise Telegram::Bot::Error }
      it { expect { subject }.to raise_error Telegram::Bot::Error }
    end
  end

  describe '#get_updates' do
    subject { bot.get_updates }
    before { expect(bot).to receive(:request).with('getUpdates') { response } }
    let(:response) { {'ok' => true, 'result' => [{'update_id' => update_id}]} }
    let(:update_id) { 123 }
    it { should be_instance_of Array }
    its(:first) { should be_instance_of Telegram::Bot::Types::Update }
    its('first.update_id') { should eq update_id }

    context 'on error' do
      let(:response) { raise Telegram::Bot::Error }
      it { expect { subject }.to raise_error Telegram::Bot::Error }
    end
  end

  describe '#delete_webhook' do
    subject { bot.delete_webhook }
    before { expect(bot).to receive(:request).with('deleteWebhook') { response } }
    let(:response) { {'ok' => true, 'result' => true} }
    it { should eq true }

    context 'on error' do
      let(:response) { raise Telegram::Bot::Error }
      it { expect { subject }.to raise_error Telegram::Bot::Error }
    end
  end
end
