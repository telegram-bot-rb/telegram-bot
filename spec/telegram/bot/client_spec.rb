RSpec.describe Telegram::Bot::Client do
  let(:instance) { described_class.new 'token' }
  let(:token) { 'token' }
  let(:botan_token) { double(:botan_token) }

  include_examples 'initializers'
  it_behaves_like 'async', request_args: -> { [double(:action), {body: :content}] }

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
        %i[c d e].each { |x| expected[x] = expected[x].to_json }
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
      let(:args) { %w[secret superbot] }
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

  describe '#request' do
    subject { -> { instance.request(action, request_body) } }
    let(:action) { :some_action }
    let(:url) { "#{format described_class::URL_TEMPLATE, token}#{action}" }
    let(:request_body) { double(:body) }
    let(:prepared_body) { double(:prepared_body) }
    let(:response) { HTTP::Message.new_response(body).tap { |x| x.status = status } }

    let(:status) { 200 }
    let(:body) { body_json.to_json }
    let(:body_json) { {'param' => 'val', 'description' => 'some description'} }
    before do
      expect(described_class).to receive(:prepare_body).with(request_body) { prepared_body }
      expect(instance).to receive(:http_request).with(url, prepared_body) { response }
    end
    around { |ex| Telegram::Bot::ClientStub.stub_all!(false) { ex.run } }

    shared_examples 'invalid body' do |error = Telegram::Bot::Error|
      context 'when body is not json' do
        let(:body) { '{' }
        it { should raise_error error }
      end
    end

    its(:call) { should eq body_json }
    include_examples 'invalid body', JSON::ParserError

    context 'when status is 403' do
      let(:status) { 403 }
      it { should raise_error Telegram::Bot::Forbidden, body_json['description'] }
      include_examples 'invalid body'
    end

    context 'when status is 404' do
      let(:status) { 404 }
      it { should raise_error Telegram::Bot::NotFound, body_json['description'] }
      include_examples 'invalid body'
    end

    context 'when status is other' do
      let(:status) { 500 }
      it { should raise_error Telegram::Bot::Error, /#{body_json['description']}/ }
    end
  end
end
