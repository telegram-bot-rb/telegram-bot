RSpec.describe Telegram::Bot::Botan::ControllerHelpers do
  include_context 'telegram/bot/updates_controller'
  let(:controller_class) do
    described_class = self.described_class
    Class.new(Telegram::Bot::UpdatesController) do
      include described_class
    end
  end
  let(:botan) { double(:botan) }
  let(:result) { double(:result) }
  let(:payload) { {from: {id: user_id}} }
  let(:payload_type) { :message }
  let(:user_id) { double(:user_id) }
  before { allow(bot).to receive(:botan) { botan } }

  shared_examples 'basic tracking' do
    context 'when botan is not configured' do
      let(:botan) {}
      it { should eq nil }
    end

    context 'when `from` is empty' do
      let(:payload) { {text: 'test'} }
      it { expect { subject }.to raise_error described_class::MissingFrom }
    end
  end

  describe '#botan_track' do
    subject { controller.send(:botan_track, event, data) }
    let(:event) { double(:event) }
    let(:data) { double(:data) }

    it 'calls botan#track' do
      expect(botan).to receive(:track).with(event, user_id, data) { result }
      should eq result
    end

    include_examples 'basic tracking'
  end

  describe '#botan_track_action' do
    subject { controller.send(:botan_track_action) }
    let(:action_name) { double(:action_name) }

    it 'calls botan#track with current action and payload' do
      expect(controller).to receive(:action_name) { action_name }
      expect(botan).to receive(:track).
        with(action_name, user_id, deep_stringify(payload)) { result }
      should eq result
    end

    include_examples 'basic tracking'
  end
end
