RSpec.describe Telegram::Bot::ClientStub do
  describe '#stub_all!' do
    let(:client) { Telegram::Bot::Client.new('token', 'bot_name') }
    let(:clients) { Telegram::Bot::Client.wrap(['token', token: 'token2']) }

    shared_examples 'constructors' do |expected_class|
      it 'makes Client.new return ClientStub' do
        expect(client).to be_instance_of expected_class
        expect(client.username).to eq 'bot_name'
      end

      it 'makes Client.wrap raturn ClientStub' do
        expect(clients).to contain_exactly instance_of(expected_class),
          instance_of(expected_class)
      end
    end

    context 'when not used' do
      include_examples 'constructors', Telegram::Bot::Client
    end

    context 'when enabled' do
      around { |ex| described_class.stub_all! { ex.run } }
      include_examples 'constructors', Telegram::Bot::ClientStub
    end

    context 'when redisabled' do
      around do |ex|
        described_class.stub_all! do
          described_class.stub_all!(false) do
            ex.run
          end
        end
      end
      include_examples 'constructors', Telegram::Bot::Client
    end
  end
end
