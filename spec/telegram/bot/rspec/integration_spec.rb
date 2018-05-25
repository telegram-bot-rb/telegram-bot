require 'telegram/bot/rspec/integration'
require 'action_controller'
require 'action_dispatch'

RSpec.describe 'Integrations helper', :telegram_bot do
  include ActionDispatch::Integration::Runner
  def reset_template_assertion
  end

  let(:app) do
    app = Telegram::Bot::Middleware.new(bot, controller)
    if ActionPack::VERSION::MAJOR >= 5
      app
    else
      require 'action_dispatch/middleware/params_parser'
      ActionDispatch::ParamsParser.new(app)
    end
  end
  let(:bot) { Telegram::Bot::ClientStub.new('token') }
  let(:controller_path) { '/' }
  let(:controller) do
    Class.new(Telegram::Bot::UpdatesController) do
      def start(*args)
        respond_with :message, text: "Start: #{args.inspect}, option: #{payload[:option]}"
      end
    end
  end

  describe '#default_message_options' do
    subject { default_message_options }
    it { should eq from: {id: from_id}, chat: {id: chat_id} }
  end

  describe '#dispatch' do
    subject { -> { dispatch message: {text: '/start', **default_message_options} } }
    it { should respond_with_message 'Start: [], option: ' }
  end

  describe '#dispatch_message' do
    subject { -> { dispatch_message "/start #{args.join ' '}", options } }
    let(:args) { %w[asd qwe] }
    let(:options) { {} }
    it { should respond_with_message "Start: #{args.inspect}, option: " }

    context 'with options' do
      let(:options) { {option: 1} }
      it { should respond_with_message "Start: #{args.inspect}, option: 1" }

      context 'and chat_id is not set' do
        let(:options) { super().merge(chat: nil) }
        it { should raise_error(/chat is not present/) }
      end
    end
  end

  describe '#dispatch_command' do
    subject { -> { dispatch_command :start, *args } }
    let(:args) { [] }
    it { should respond_with_message "Start: #{args.inspect}, option: " }

    context 'with args' do
      let(:args) { %w[asd qwe] }
      it { should respond_with_message "Start: #{args.inspect}, option: " }
    end

    context 'with options' do
      let(:args) { ['asd', 'qwe', option: 1] }
      it { should respond_with_message "Start: #{args[0...-1].inspect}, option: 1" }
    end
  end

  describe 'callback queries', :callback_query do
    let(:controller) do
      Class.new(Telegram::Bot::UpdatesController) do
        include Telegram::Bot::UpdatesController::CallbackQueryContext

        def callback_query(data = nil, *)
          answer_callback_query "data: #{data}"
        end

        def context_callback_query(data = nil, *)
          answer_callback_query "data: #{data}", extra: :param
        end

        def answer_and_edit_callback_query(data = nil, *)
          answer_callback_query "data: #{data}"
          edit_message :text, text: 'edited-text', extra: :param
        end
      end
    end

    describe '#callback_query' do
      let(:data) { 'unknown:command' }
      it { should answer_callback_query("data: #{data}") }
    end

    describe '#context_callback_query' do
      let(:data) { 'context:test:payload' }
      it { should answer_callback_query('data: test:payload', extra: :param) }
      it { should_not edit_current_message(:text) }
    end

    describe '#answer_and_edit_callback_query' do
      let(:data) { 'answer_and_edit:test:payload' }
      it do
        should answer_callback_query(/test:payload/).
          and edit_current_message(:text, text: /edited/, extra: :param)
      end
    end
  end
end
