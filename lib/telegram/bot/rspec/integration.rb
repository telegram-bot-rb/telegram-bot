require 'telegram/bot'
Telegram::Bot.deprecation_0_15.warn(
  "`require 'telegram/bot/rspec/integration'` is deprecated in favor of " \
  "`require 'telegram/bot/rspec/integration/rails'`"
)
require 'telegram/bot/rspec/integration/rails'

Telegram::Bot::RSpec.with_include_context do |config|
  config.include_context 'telegram/bot/integration/rails', telegram_bot: true
end
