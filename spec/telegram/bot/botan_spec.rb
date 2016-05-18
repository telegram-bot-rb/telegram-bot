RSpec.describe Telegram::Bot::Botan do
  let(:instance) { described_class.new 'token' }
  let(:token) { 'token' }

  include_examples 'initializers', :botans

  describe '.new' do
    subject { described_class.new(*args) }

    context 'when usual args are given' do
      let(:args) { ['secret'] }
      its(:token) { should eq args[0] }
    end

    context 'when options are given' do
      let(:args) { [token: 'secret'] }
      its(:token) { should eq args[0][:token] }
    end
  end
end
