# frozen_string_literal: true

RSpec.describe Telegram::Bot::UpdatesController::LogSubscriber do
  let(:instance) { described_class.new }
  let(:logger) { double(:logger) }
  let(:event) do
    ActiveSupport::Notifications::Event.new(
      'start_processing', Time.current, Time.current, 1, payload
    )
  end
  let(:payload) { {controller: 'MyController', action: 'start', update: update} }
  let(:update) { {'message' => {'text' => 'some secret text', 'chat' => {'id' => 1}}} }
  let(:message) do
    result = nil
    allow(logger).to receive(:info) { |&block| result = block.call }
    instance.start_processing(event)
    result
  end

  before { allow(Telegram::Bot::UpdatesController).to receive(:logger) { logger } }
  after { described_class.filtered_parameters = %i[text] }

  it 'filters text out of the logged update' do
    expect(message).not_to include('some secret text')
    expect(message).to include('[FILTERED]')
    expect(message).to include('"id":1')
  end

  context 'when filtered_parameters is set to an empty list' do
    before { described_class.filtered_parameters = [] }

    it 'logs update as is' do
      expect(message).to include('some secret text')
    end
  end
end
