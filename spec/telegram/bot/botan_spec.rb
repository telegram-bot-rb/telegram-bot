RSpec.describe Telegram::Bot::Botan do
  let(:instance) { described_class.new 'token' }
  let(:token) { 'token' }

  include_examples 'initializers', :botans
  it_behaves_like 'async', request_args: -> { [double(:method), double(:url)] }

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

  describe '.prepare_async_args' do
    subject { described_class.prepare_async_args(*input) }
    let(:input) { [:post, :uri, {a: 1, b: :sym, 'd' => 'str'}, 'body'] }
    it { should eq ['post', 'uri', {a: 1, b: 'sym', 'd' => 'str'}, 'body'] }
  end
end
