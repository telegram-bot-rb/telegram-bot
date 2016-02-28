RSpec.shared_context 'telegram/bot/updates_controller' do
  let(:controller_class) { described_class }
  let(:instance) { controller_class.new(bot, update) }
  let(:update) { {payload_type => payload} }
  let(:payload_type) { 'some_type' }
  let(:payload) { double(:payload) }
  let(:bot) { Telegram::Bot::ClientStub.new(bot_name) }
  let(:bot_name) { 'bot' }
  let(:session) do
    session = Telegram::Bot::UpdatesController::Session::TestSessionHash.new
    allow_any_instance_of(controller_class).to receive(:session) { session }
    session
  end

  def dispatch_message(text, options = {})
    payload = build_payload :message, options.merge(text: text)
    controller_class.dispatch bot, payload
  end

  def build_payload(type, content)
    deep_stringify type => content
  end

  def deep_stringify(input)
    case input
    when Array then input.map(&method(__callee__))
    when Hash then input.transform_keys(&:to_s).transform_values(&method(__callee__))
    else input
    end
  end
end
