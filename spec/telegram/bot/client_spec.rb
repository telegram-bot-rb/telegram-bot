RSpec.describe Telegram::Bot::Client do
  let(:instance) { described_class.new 'token' }
  let(:token) { 'token' }
  let(:botan_token) { double(:botan_token) }

  describe '.wrap' do
    subject { described_class.wrap(input) }
    let(:result) { double(:result) }
    let(:username) { 'username' }

    context 'when input is a string' do
      let(:input) { token }

      it 'treats string as token' do
        expect(described_class).to receive(:new).with(token) { result }
        should eq result
      end
    end

    context 'when input is a hash' do
      let(:input) { {token: token, username: username, ignore: :ignore} }

      it 'extracts token & username' do
        expect(described_class).to receive(:new).
          with(token, username, botan: nil) { result }
        should eq result
      end

      context 'when `botan` is given' do
        let(:input) { super().merge(botan: botan_token) }

        it 'passes it to initializer' do
          expect(described_class).to receive(:new).
            with(token, username, botan: botan_token) { result }
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
      let(:input) { :bot_1 }
      before { allow(Telegram).to receive(:bots) { {bot_1: instance} } }
      it { should eq Telegram.bots[:bot_1] }

      context 'and there is no such bot' do
        let(:input) { :invalid }
        it { expect { subject }.to raise_error(/not configured/) }
      end
    end

    context 'when input is an array' do
      let!(:input) { ['other_token', instance, token: token, username: username] }
      let(:result_2) { double(:result_2) }

      it 'calls wrap for every element' do
        expect(described_class).to receive(:new).with('other_token') { result }
        expect(described_class).to receive(:new).with(token, username, botan: nil) { result_2 }
        should eq [result, instance, result_2]
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
        %i(c d e).each { |x| expected[x] = expected[x].to_json }
        should eq expected
      end
    end
  end

  describe '#botan' do
    subject { instance.botan }
    it { should eq nil }

    context 'when botan token is set' do
      let(:instance) { described_class.new token, botan: botan_token }
      it { should be_instance_of Telegram::Bot::Botan }
      its(:token) { should eq botan_token }
    end
  end
end
