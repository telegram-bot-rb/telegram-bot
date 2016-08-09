RSpec.describe Telegram::Bot::Client do
  let(:instance) { described_class.new(*client_args) }
  let(:token) { 'token' }
  let(:botan_token) { double(:botan_token) }
  let(:client_id) { 'client_id' }
  let(:client_args) { [token] }

  describe '#botan' do
    subject { instance.botan }
    it { should eq nil }

    context 'when botan token is set' do
      let(:client_args) { [token, id: client_id, async: Class.new, botan: botan_token] }
      it { should be_instance_of Telegram::Bot::Botan }
      its(:token) { should eq botan_token }
    end

    context 'when botan is configured with hash' do
      let(:client_args) { [token, id: client_id, async: Class.new, botan: botan_config] }
      let(:botan_config) { {token: botan_token, async: Class.new} }
      it { should be_instance_of Telegram::Bot::Botan }
      its(:token) { should eq botan_token }
    end
  end
end
