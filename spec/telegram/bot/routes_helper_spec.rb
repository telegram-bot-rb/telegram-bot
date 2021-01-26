require 'telegram/bot/routes_helper'

RSpec.describe Telegram::Bot::RoutesHelper do
  let(:bot) { create_bot('bot_token') }
  let(:other_bot) { create_bot('other_token') }
  let(:bots) { {default: bot, other: other_bot} }

  def create_bot(*args)
    Telegram::Bot::Client.new(*args)
  end

  describe '.route_name_for_bot' do
    subject { described_class.route_name_for_bot(input) }
    before { expect(Telegram).to receive(:bots) { bots } }

    context 'when there is only one bot' do
      let(:bots) { {default: bot} }

      context 'for existing bot' do
        let(:input) { bot }
        it { should eq 'telegram_webhook' }
      end

      context 'for non-existing bot' do
        let(:input) { other_bot }
        it { should eq 'telegram_webhook' }
      end
    end

    context 'when there are multiple bots' do
      context 'for existing bot' do
        let(:input) { bot }
        it { should eq 'default_telegram_webhook' }
      end

      context 'for non-existing bot' do
        let(:input) { double(:missing_bot) }
        it { should eq 'telegram_webhook' }
      end
    end
  end

  describe '#telegram_webhook' do
    subject { ->(*args, **kwargs) { mapper.telegram_webhook(*args, **kwargs) } }
    let(:mapper) { double(:mapper).tap { |x| x.extend described_class } }
    let(:controller) { double(:controller, name: :controller) }
    before { allow(Telegram).to receive(:bots) { bots } }

    def assert_route(bot, controller, path: nil, **expected_options) # rubocop:disable AbcSize
      path ||= "telegram/#{described_class.token_hash(bot.token)}"
      expect(mapper).to receive(:post) do |actual_path, actual_options|
        expect(actual_path).to eq(path)
        middleware = actual_options[:to]
        expect(middleware.controller).to eq(controller)
        expect(middleware.bot.token).to eq(bot.token)
        expect(middleware.bot.username).to eq(bot.username)
        expect(actual_options).to include(expected_options)
      end
      yield
    end

    it 'creates routes for default bot' do
      assert_route(bot, controller, as: 'default_telegram_webhook') do
        subject[controller]
      end

      other_controller = double(:other_controller, name: :other_controller)
      assert_route(bot, other_controller, as: 'custom_route') do
        subject[other_controller, as: 'custom_route']
      end
    end

    it 'passes extra options' do
      assert_route(bot, controller, as: 'default_telegram_webhook', option: :val, other: 2) do
        subject[controller, option: :val, other: 2]
      end
    end

    it 'uses :path param to override default path' do
      assert_route(bot, controller, as: 'default_telegram_webhook', path: 'custom/path') do
        subject[controller, path: 'custom/path']
      end
    end

    context 'when bot does not have configured token' do
      let(:bot) { create_bot(nil) }
      it 'creates route anyway' do
        assert_route(bot, controller, as: 'default_telegram_webhook', path: 'telegram/') do
          subject[controller]
        end
      end
    end

    context 'when called with controller and smth castable to bot' do
      it 'creates routes for every created bot and controller' do
        assert_route(create_bot('custom_token'), controller, as: 'telegram_webhook') do
          subject[controller, 'custom_token']
        end
      end
    end
  end
end
