RSpec.describe Telegram::Bot::ClientStub do
  describe '#stub_all!' do
    let(:client) { Telegram::Bot::Client.new('token', 'bot_name') }
    let(:clients) { ['token', token: 'token2'].map(&Telegram::Bot::Client.method(:wrap)) }

    shared_examples 'constructors' do |expected_class|
      it 'makes Client.new return ClientStub' do
        expect(client).to be_instance_of expected_class
        expect(client.username).to eq 'bot_name'
      end

      it 'makes Client.wrap return ClientStub' do
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

  describe '#new' do
    subject { described_class.new(*args, **kwargs) }
    let(:args) { [] }
    let(:kwargs) { {} }

    context 'when only username is given' do
      let(:args) { ['superbot'] }
      its(:username) { should eq args[0] }
    end

    context 'when username and token are given' do
      let(:args) { %w[token superbot] }
      its(:token) { should eq args[0] }
      its(:username) { should eq args[1] }
    end

    context 'when hash config is given' do
      let(:kwargs) { {token: 'token', username: 'superbot'} }
      its(:token) { should eq kwargs[:token] }
      its(:username) { should eq kwargs[:username] }
    end
  end
end
