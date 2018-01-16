RSpec.describe Telegram::Bot::UpdatesPoller do
  let(:instance) { described_class.new(bot, controller) }
  let(:bot) { Telegram::Bot::Client.new('token') }
  let(:controller) { double(:controller) }

  describe '#initialize' do
    subject { instance }
    it { should be }
  end

  describe '#process_updates' do
    subject { -> { instance.process_updates(updates) } }
    let(:block) { ->(x) { expect(x).to eq expected_results.shift } }
    let(:updates) { [{update_id: 12}, {update_id: 34}].as_json }
    let(:processed_updates) { [] }
    before do
      allow(controller).to receive(:dispatch) do |bot, update|
        expect(bot).to eq self.bot
        processed_updates << update
      end
    end

    it { should change(instance, :offset).to(updates.last['update_id'] + 1) }
    it { should change(self, :processed_updates).to(updates) }

    context 'with typed response' do
      let(:updates) { super().map { |x| Telegram::Bot::Types::Update.new(x) } }
      it { should change(instance, :offset).to(updates.last['update_id'] + 1) }
      it { should change(self, :processed_updates).to(updates) }
    end
  end

  describe '#fetch_updates' do
    subject { instance.fetch_updates }
    let(:updates) { [{update_id: 12}, {update_id: 34}] }
    let(:request_result) { {ok: true, result: updates}.as_json }
    before do
      allow(bot).to receive(:get_updates) do
        expect(bot.async).to be_falsy
        request_result
      end
    end

    it { should eq updates.as_json }

    context 'with typed response' do
      let(:updates) { super().map { |x| Telegram::Bot::Types::Update.new(x.as_json) } }
      let(:request_result) { updates }
      it { should eq updates }
    end

    context 'when bot is in async mode' do
      let(:bot) { Telegram::Bot::Client.new('token', async: Class.new) }
      it { should eq updates.as_json }
    end
  end
end
