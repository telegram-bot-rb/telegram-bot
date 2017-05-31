RSpec.shared_context 'telegram/bot/integration' do
  let(:bot) { Telegram.bot }
  let(:from_id) { 123 }
  let(:chat_id) { 456 }
  let(:chat_hash) { {id: chat_id} }
  let(:default_message_options) { {from: {id: from_id}, chat: chat_hash} }
  let(:controller_path) do
    route_name = Telegram::Bot::RoutesHelper.route_name_for_bot(bot)
    Rails.application.routes.url_helpers.public_send("#{route_name}_path")
  end
  let(:request_headers) do
    {
      'ACCEPT' => 'application/json',
      'Content-Type' => 'application/json',
    }
  end
  let(:clear_session?) { described_class.respond_to?(:session_store) }
  before { described_class.session_store.try!(:clear) if clear_session? }

  include Telegram::Bot::RSpec::ClientMatchers

  def dispatch(update)
    if ActionPack::VERSION::MAJOR >= 5
      post(controller_path, params: update.to_json, headers: request_headers)
    else
      post(controller_path, update.to_json, request_headers)
    end
  end

  def dispatch_message(text, options = {})
    dispatch message: default_message_options.merge(options).merge(text: text)
  end

  def dispatch_command(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    dispatch_message("/#{args.join ' '}", options)
  end

  # Matcher to check response. Make sure to define `let(:chat_id)`.
  def respond_with_message(expected)
    raise 'Define chat_id to use respond_with_message' unless defined?(chat_id)
    send_telegram_message(bot, expected, chat_id: chat_id)
  end
end

RSpec.configure do |config|
  if config.respond_to?(:include_context)
    config.include_context 'telegram/bot/integration', :telegram_bot
  end
end
