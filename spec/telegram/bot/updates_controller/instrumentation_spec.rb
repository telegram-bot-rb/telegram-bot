RSpec.describe Telegram::Bot::UpdatesController::Instrumentation do
  include_context 'telegram/bot/updates_controller'

  subject { -> { dispatch } }
  let(:update) { {message: default_message_options.merge(text: '/start')} }

  let(:controller_class) do
    Class.new(Telegram::Bot::UpdatesController) do
      def start!(*)
      end
    end
  end

  let(:action_scope) { 'updates_controller.bot.telegram' }
  let(:events) { Hash.new { |h, k| h[k] = [] } }
  let!(:subscriber) do
    ActiveSupport::Notifications.subscribe(/#{action_scope}/) do |action, *args|
      events[action] << args
    end
  end
  after { ActiveSupport::Notifications.unsubscribe(subscriber) }

  def actions_list(*prefixes)
    prefixes.map { |x| action_name(x) }
  end

  def action_name(prefix)
    "#{prefix}.#{action_scope}"
  end

  describe '#process_action' do
    it 'fires start_processing and process_action events' do
      should change(events, :keys).by(actions_list(:start_processing, :process_action))

      action = action_name(:start_processing)
      expect(events[action].size).to eq(1)
      expect(events[action][0].last).to include(update: deep_stringify(update))

      action = action_name(:process_action)
      expect(events[action].size).to eq(1)
      expect(events[action][0].last).to include(update: deep_stringify(update))
    end
  end

  describe '#halted_callback_hook' do
    let(:controller_class) do
      super().try(:class_eval) do |x|
        x.before_action :halter_method

        def halter_method
          require 'active_support/version'
          if ActiveSupport::VERSION::MAJOR >= 5
            throw :abort
          else
            false
          end
        end

        self
      end
    end

    it 'fires halted_callback event' do
      should change(events, :keys).
        by(actions_list(:start_processing, :halted_callback, :process_action))

      action = action_name(:halted_callback)
      expect(events[action].size).to eq(1)
      expect(events[action][0].last).to include(filter: :halter_method)
    end
  end

  describe '#respond_with' do
    before do
      def controller.start!(*)
        respond_with :message, text: 'sample response'
      end
    end

    it 'fires respond_with event' do
      should change(events, :keys).
        by(actions_list(:start_processing, :respond_with, :process_action))

      action = action_name(:respond_with)
      expect(events[action].size).to eq(1)
      expect(events[action][0].last).to include(type: :message)
    end
  end
end
