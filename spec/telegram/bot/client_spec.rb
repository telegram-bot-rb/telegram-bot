RSpec.describe Telegram::Bot::Client do
  describe '.wrap' do
    subject { described_class.wrap(input) }
    let(:result) { double(:result) }
    let(:token) { 'token' }
    let(:username) { 'username' }
    let(:instance) { described_class.new 'token' }

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
        expect(described_class).to receive(:new).with(token, username) { result }
        should eq result
      end
    end

    context 'when input is an instance of described_class' do
      let!(:input) { instance }

      it 'returns input' do
        expect(described_class).to_not receive(:new)
        should eq input
      end
    end

    context 'when input is an array' do
      let!(:input) { ['other_token', instance, token: token, username: username] }
      let(:result_2) { double(:result_2) }

      it 'calls wrap for every element' do
        expect(described_class).to receive(:new).with('other_token') { result }
        expect(described_class).to receive(:new).with(token, username) { result_2 }
        should eq [result, instance, result_2]
      end
    end
  end
end
