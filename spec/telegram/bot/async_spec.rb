RSpec.describe Telegram::Bot::Async::Job do
  let(:job_class) do
    described_class = self.described_class
    client_class = self.client_class
    Class.new do
      include described_class
      self.client_class = client_class
    end
  end
  let(:client_class) { Telegram::Bot::Client }
  let(:instance) { job_class.new }

  describe '#perform' do
    subject { instance.perform(id, *args) }
    let(:id) { 'bot_id' }
    let(:args) { [double(:action), {body: :content}] }
    let(:client) { Telegram::Bot::Client.new(async: custom_job_class) }
    let(:custom_job_class) { Class.new }
    let(:result) { double(status: 200, body: '{"test":"ok"}') }

    it 'finds client and performs request' do
      expect(client_class).to receive(:wrap).with(id.to_sym) { client }
      expect(client).to receive(:request).with(*args).and_call_original
      expect(client).to receive(:http_request) { result }
      should eq 'test' => 'ok'
    end
  end
end
