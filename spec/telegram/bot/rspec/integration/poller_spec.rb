require 'telegram/bot/rspec/integration/poller'

RSpec.describe 'Poller integration spec', telegram_bot: :poller do
  include_examples 'shared integration examples'
end
