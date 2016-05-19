RSpec.describe Telegram::Bot::Client do
  let(:instance) { described_class.new 'token' }
  let(:token) { 'token' }
  let(:botan_token) { double(:botan_token) }

  include_examples 'initializers'
  include_examples 'async', request_args: -> { [double(:action), {body: :content}] }

  describe '.prepare_body' do
    subject { described_class.prepare_body(input) }

    context 'when plain hash is given' do
      let(:input) { {a: 1, b: '2', c: nil} }
      it { should eq input }
    end

    context 'when nested hash is given' do
      let(:input) { {a: 1, b: '2', c: [1, 2], d: {a: 1}, e: {b: []}} }

      it 'encodes nested hashes to json' do
        expected = input.dup
        %i(c d e).each { |x| expected[x] = expected[x].to_json }
        should eq expected
      end
    end
  end

  describe '.prepare_async_args' do
    subject { described_class.prepare_async_args(*input) }
    let(:input) { [:action, a: 1, b: :sym, c: [:other], 'd' => 'str'] }
    it { should eq ['action', a: 1, b: 'sym', c: '["other"]', 'd' => 'str'] }
  end

  describe '.new' do
    subject { described_class.new(*args) }

    context 'when multiple args are given' do
      let(:args) { %w(secret superbot) }
      its(:token) { should eq args[0] }
      its(:username) { should eq args[1] }
      its(:base_uri) { should include args[0] }
    end

    context 'when hash is given' do
      let(:args) { [token: 'secret', username: 'superbot'] }
      its(:token) { should eq args[0][:token] }
      its(:username) { should eq args[0][:username] }
      its(:base_uri) { should include args[0][:token] }
    end
  end
end
