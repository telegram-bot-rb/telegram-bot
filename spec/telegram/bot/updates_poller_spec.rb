RSpec.describe Telegram::Bot::UpdatesPoller do
  let(:instance) { described_class.new(bot, controller) }
  let(:bot) { Telegram::Bot::Client.new('token') }
  let(:controller) { double(:controller) }

  describe '#initialize' do
    subject { instance }
    it { should be }
  end

  describe '#fetch_updates' do
    subject { -> { instance.fetch_updates(&block) } }
    let(:block) { ->(x) { expect(x).to eq expected_results.shift } }
    let(:results) { [{update_id: 12}, {update_id: 34}] }
    let(:expected_results) { results.as_json }
    let(:request_result) { {ok: true, result: results}.as_json }
    before do
      allow(bot).to receive(:get_updates) do
        expect(bot.async).to be_falsy
        request_result
      end
    end

    it { should change(instance, :offset).to(results.last[:update_id] + 1) }
    it { should change { expected_results }.to([]) }

    context 'with typed response' do
      let(:request_result) { results.as_json.map { |x| Telegram::Bot::Types::Update.new(x) } }
      let(:expected_results) { request_result.dup }
      it { should change(instance, :offset).to(results.last[:update_id] + 1) }
      it { should change { expected_results }.to([]) }
    end

    context 'when bot is in async mode' do
      let(:bot) { Telegram::Bot::Client.new('token', async: Class.new) }
      it { should change { expected_results }.to([]) }
    end
  end
end
