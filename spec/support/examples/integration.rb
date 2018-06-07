RSpec.shared_examples 'shared integration examples' do
  let(:bot) { Telegram::Bot::ClientStub.new('token') }
  let(:controller_class) do
    Class.new(Telegram::Bot::UpdatesController) do
      def start!(data = nil, *)
        respond_with :message, text: "Hi #{data}"
      end

      def callback_query(data, *)
        answer_callback_query "pong: #{data}"
      end
    end
  end

  describe '#start' do
    subject { -> { dispatch_command(:start, :test_data) } }
    it { should respond_with_message('Hi test_data') }
  end

  describe '#callback_query', :callback_query do
    let(:data) { :test_data }
    it { should answer_callback_query "pong: #{data}" }
  end
end
