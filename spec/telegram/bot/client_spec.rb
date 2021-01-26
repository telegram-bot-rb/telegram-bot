RSpec.describe Telegram::Bot::Client do
  let(:instance) { described_class.new 'token' }
  let(:token) { 'token' }

  it_behaves_like 'async', request_args: -> { [double(:action), {body: :content}] }

  describe '.wrap' do
    subject { described_class.wrap(input, **options) }
    let(:options) { {} }
    let(:result) { double(:result) }
    let(:username) { 'username' }

    context 'when input is a string' do
      let(:input) { token }

      it 'treats string as token' do
        expect(described_class).to receive(:new) do |*args, **kwargs|
          expect([*args, kwargs]).to eq([token, {}]) # not using .with to support ruby 2.x and 3.x
          result
        end
        should eq result
      end

      context 'and additional options are given' do
        let(:options) { {id: :test} }

        it 'passes them to initializer' do
          expect(described_class).to receive(:new).with(input, **options) { result }
          should eq result
        end
      end
    end

    context 'when input is a hash' do
      let(:input) { {token: token, 'username' => username, other: :options} }

      it 'passes it with symbolized keys' do
        expect(described_class).to receive(:new).with(**input.symbolize_keys) { result }
        should eq result
      end

      context 'and additional options are given' do
        let(:options) { {id: :test} }

        it 'passes them to initializer' do
          expect(described_class).to receive(:new).
            with(**input.symbolize_keys, **options) { result }
          should eq result
        end
      end
    end

    context 'when input is an instance of described_class' do
      let!(:input) { instance }

      it 'returns input' do
        expect(described_class).to_not receive(:new)
        should eq input
      end
    end

    context 'when input is a Symbol' do
      let(:input) { :client_1 }
      before { allow(Telegram).to receive(:bots) { {client_1: instance} } }
      it { should eq Telegram.bots[:client_1] }

      context 'and there is no such bot' do
        let(:input) { :invalid }
        it { expect { subject }.to raise_error(/not configured/) }
      end
    end
  end

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
    subject { described_class.new(*args, **kwargs) }
    let(:args) { [] }
    let(:kwargs) { {} }
    let(:token) { 'secret' }
    let(:username) { 'superbot' }

    context 'when multiple args are given' do
      let(:args) { [token, username] }
      its(:token) { should eq token }
      its(:username) { should eq username }
      its(:base_uri) { should eq "#{described_class::SERVER}/bot#{token}/" }
    end

    context 'when hash is given' do
      let(:kwargs) { {token: 'secret', username: 'superbot'} }
      its(:token) { should eq token }
      its(:username) { should eq username }
      its(:base_uri) { should eq "#{described_class::SERVER}/bot#{token}/" }
    end

    context 'with custom server' do
      let(:server) { 'http://my.server' }
      let(:args) { [token, username] }
      let(:kwargs) { {server: server} }
      its(:base_uri) { should eq "#{server}/bot#{token}/" }

      context 'and hash options' do
        let(:kwargs) { {token: token, username: username, server: server} }
        its(:base_uri) { should eq "#{server}/bot#{token}/" }
      end
    end
  end

  describe '#request' do
    subject { -> { instance.request(action, request_body) } }
    let(:action) { :some_action }
    let(:url) do
      base_uri = format(described_class::URL_TEMPLATE,
        server: described_class::SERVER,
        token: token,
      )
      "#{base_uri}#{action}"
    end
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
