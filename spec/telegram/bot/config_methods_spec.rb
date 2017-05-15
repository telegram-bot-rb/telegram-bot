RSpec.describe Telegram::Bot::ConfigMethods do
  let(:registry) do
    Object.new.tap do |x|
      x.extend described_class
      x.bots_config = config
    end
  end
  let(:config) do
    {
      default: 'default_token',
      chat: {
        token: 'chat_token',
        username: 'Chat',
        botan: 'chat_botan_token',
      },
      other_chat: {
        'token' => 'other_chat_token',
        'username' => 'OtherChat',
        'botan' => 'other_chat_botan_token',
      },
    }
  end

  describe '#bot' do
    subject { -> { registry.bot } }
    its(:call) { should eq registry.bots[:default] }

    context 'when bot is not configured' do
      let(:config) { super().except(:default) }
      it { should raise_error(/bot is not configured/) }
    end
  end

  describe '#bots' do
    context 'configured by token' do
      subject { registry.bots[:default] }
      its(:id) { should eq :default }
      its(:token) { should eq config[:default] }
    end

    context 'configured by hash' do
      subject { registry.bots[:chat] }
      its(:id) { should eq :chat }
      its(:token) { should eq config[:chat][:token] }
      its(:username) { should eq config[:chat][:username] }
      its('botan.token') { should eq config[:chat][:botan] }
    end

    context 'configured by hash with stringified keys' do
      subject { registry.bots[:other_chat] }
      its(:id) { should eq :other_chat }
      its(:token) { should eq config[:other_chat]['token'] }
      its(:username) { should eq config[:other_chat]['username'] }
      its('botan.token') { should eq config[:other_chat]['botan'] }
    end
  end

  describe '#botans' do
    subject { registry.botans }
    it do
      should eq(
        default: nil,
        chat: registry.bots[:chat].botan,
        other_chat: registry.bots[:other_chat].botan,
      )
    end
  end

  describe '#bots_config' do
    subject { registry.bots_config }
    it { should eq config }

    context 'when not configured' do
      let(:registry) { Object.new.tap { |x| x.extend described_class } }
      before { hide_const('Rails') }
      it { should eq({}) }

      context 'in rails environment' do
        before { stub_const('Rails', double(application: double(secrets: secrets))) }
        let(:secrets) { {} }
        it { should eq({}) }

        context 'when there is telegram section in secrets' do
          let(:secrets) { {telegram: config.stringify_keys} }
          let(:config) do
            {
              bot: double(:bot_config),
              bots: {
                chat: double(:chat_config),
                other_chat: double(:other_chat_config),
              },
            }
          end
          it { should include default: config[:bot] }
          it { should include config[:bots] }

          context 'on rails >5.1 (deep symbolized keys)' do
            let(:secrets) { {telegram: config.deep_symbolize_keys} }
            it { should include default: config[:bot] }
            it { should include config[:bots] }
          end
        end
      end
    end
  end
end
