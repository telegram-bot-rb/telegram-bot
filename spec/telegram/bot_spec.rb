RSpec.describe Telegram::Bot do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  describe described_class::StaleChat do
    describe '.match_response?' do
      subject { ->(val) { described_class.match_response?(val) } }

      it 'returns true for specific errors' do
        expect(subject.call({})).to eq false
        expect(subject.call('description' => 'test')).to eq false
        expect(subject.call('description' => 'Error: bot was kicked from')).to eq true
        expect(subject.call(
          'description' => "Forbidden: can't write to private chat with deleted user"
        )).to eq true
        expect(subject.call(
          'description' => 'Bad request: group chat is deactivated'
        )).to eq true
        expect(subject.call(
          'description' => 'Forbidden: Bot was blocked by the user'
        )).to eq true
      end
    end
  end
end
