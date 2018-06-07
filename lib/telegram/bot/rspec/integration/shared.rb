require 'active_support/json'
require 'telegram/bot'
require 'telegram/bot/rspec/message_helpers'
require 'telegram/bot/rspec/callback_query_helpers'

RSpec.shared_context 'telegram/bot/integration/shared' do
  include Telegram::Bot::RSpec::ClientMatchers
  include_context 'telegram/bot/message_helpers'
  include_context 'telegram/bot/callback_query', :callback_query

  let(:bot) { Telegram.bot }
  let(:clear_session?) { described_class.respond_to?(:session_store) }
  before { described_class.session_store.try!(:clear) if clear_session? }
end
