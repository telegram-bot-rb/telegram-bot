RSpec.shared_examples 'async' do |request_args: -> {}|
  let(:instance) { described_class.new(token: token, id: id, async: async) }
  let(:id) { :default_bot }
  let(:async) { true }
  let!(:application_job_class) do
    klass = Class.new do
      def self.perform_later(*)
      end
    end
    klass.tap { |x| stub_const('ApplicationJob', x) }
  end
  after { described_class.default_async_job = nil }

  describe '#async' do
    subject { ->(*args, &block) { instance.async(*args, &block) } }
    its(:call) { should eq described_class.default_async_job }

    context 'when async is disabled' do
      let(:async) { false }
      its(:call) { should eq false }
    end

    context 'when using with block' do
      it 'sets value inside block' do
        expect do
          expect do
            subject.call(false) do
              expect do
                subject.call(nil) { expect(subject[]).to eq nil }
              end.to_not change(&subject).from false
              raise 'TestError'
            end
          end.to raise_error(/TestError/)
        end.to_not change(instance, :async).from(described_class.default_async_job)
      end
    end
  end

  describe '.default_async_job' do
    subject { described_class.default_async_job }
    its(:superclass) { should eq application_job_class }
    it { should include Telegram::Bot::Async::Job }
    its(:client_class) { should eq described_class }

    context 'when ApplicationJob is not defined' do
      let(:application_job_class) {}
      it { expect { subject }.to raise_error(/Define ApplicationJob/) }
    end
  end

  describe '#request' do
    subject { ->(*args) { instance.request(*(args.empty? ? self.args : args)) } }
    let(:args, &request_args)
    let(:result) { double(:result) }

    shared_examples 'enqueues job' do
      it 'enqueues job' do
        expect(instance).to_not receive(:http_request)
        expect(described_class).to receive(:prepare_async_args).with(*args) { args }
        expect(instance.async).to receive(:perform_later).with(id.to_s, *args) { result }
        expect(subject.call).to eq result
      end
    end

    include_examples 'enqueues job'

    context 'with custom job class' do
      let(:async) { double(:job_class) }
      include_examples 'enqueues job'
    end

    context 'when id is not set' do
      let(:id) {}
      it { should raise_error(/Can not enqueue/) }
    end

    context 'when async is disabled' do
      let(:async) { false }
      let(:result) { double(status: 200, body: '{"test":"ok"}') }
      let(:args, &request_args)

      it 'performs request immediately' do
        expect(instance).to receive(:request).with(*args).and_call_original
        expect(instance).to receive(:http_request) { result }
        expect(subject[]).to eq 'test' => 'ok'
      end
    end
  end
end
