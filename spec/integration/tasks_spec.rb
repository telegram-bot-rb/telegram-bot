# frozen_string_literal: true

require 'integration_helper'

RSpec.describe Telegram::Bot::Tasks, type: :request do
  include Telegram::Bot::RSpec::ClientMatchers

  def stub_env(new_values)
    new_values.stringify_keys!
    old_values = ENV.to_h.slice(new_values.keys)
    new_values.each { |k, v| ENV[k] = v.to_s }
    yield
  ensure
    new_values.each_key { |k| ENV[k] = old_values[k] }
  end

  shared_examples 'uses BOT envar' do |bot_matcher|
    it 'runs for all bots by default' do
      matcher = Telegram.bots.values.map { |x| instance_exec(x, &bot_matcher) }.reduce(&:and)
      expect(subject).to matcher
    end

    context 'when BOT specified' do
      around { |ex| stub_env(BOT: :other) { ex.run } }

      it 'runs for this bot only' do
        expect(subject).to instance_exec(Telegram.bots[:other], &bot_matcher)
      end
    end
  end

  describe '#log_out' do
    subject { -> { described_class.log_out } }
    include_examples 'uses BOT envar', ->(bot) { make_telegram_request(bot, :logOut) }
  end

  describe '#close' do
    subject { -> { described_class.close } }
    include_examples 'uses BOT envar', ->(bot) { make_telegram_request(bot, :close) }
  end

  describe '#set_webhook' do
    subject { -> { described_class.set_webhook } }
    include_examples 'uses BOT envar', ->(bot) { make_telegram_request(bot, :setWebhook) }

    context 'with options in env' do
      around do |ex|
        stub_env(IP_ADDRESS: '1.2.3.4', DROP_PENDING_UPDATES: 'TrUe') do
          ex.run
        end
      end
      include_examples 'uses BOT envar', ->(bot) {
        make_telegram_request(bot, :setWebhook).with(hash_including(
          ip_address: '1.2.3.4',
          drop_pending_updates: true,
        ))
      }
    end
  end

  describe '#delete_webhook' do
    subject { -> { described_class.delete_webhook } }
    include_examples 'uses BOT envar', ->(bot) { make_telegram_request(bot, :deleteWebhook) }

    context 'with options in env' do
      around { |ex| stub_env(DROP_PENDING_UPDATES: 'TrUe') { ex.run } }
      include_examples 'uses BOT envar', ->(bot) {
        make_telegram_request(bot, :deleteWebhook).with(hash_including(
          drop_pending_updates: true,
        ))
      }
    end
  end
end
