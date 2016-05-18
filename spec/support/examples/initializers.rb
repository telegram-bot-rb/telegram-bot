RSpec.shared_examples 'initializers' do |config_method = :bots|
  describe '.wrap' do
    subject { described_class.wrap(input, **options) }
    let(:options) { {} }
    let(:result) { double(:result) }
    let(:username) { 'username' }

    context 'when input is a string' do
      let(:input) { token }

      it 'treats string as token' do
        expect(described_class).to receive(:new).with(token, {}) { result }
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
      before { allow(Telegram).to receive(config_method) { {client_1: instance} } }
      it { should eq Telegram.send(config_method)[:client_1] }

      context 'and there is no such bot' do
        let(:input) { :invalid }
        it { expect { subject }.to raise_error(/not configured/) }
      end
    end
  end
end
