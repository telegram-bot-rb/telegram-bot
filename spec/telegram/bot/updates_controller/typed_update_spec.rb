RSpec.describe Telegram::Bot::UpdatesController::TypedUpdate do
  include_context 'telegram/bot/updates_controller'
  let(:controller_class) do
    described_class = self.described_class
    Class.new(Telegram::Bot::UpdatesController) do
      include described_class
    end
  end

  context 'when `update` is a virtus model' do
    subject { controller }
    unique_types = (Telegram::Bot::UpdatesController::PAYLOAD_TYPES - %w[
      edited_message
      channel_post
      edited_channel_post
      my_chat_member
      chat_member
    ]).
      map { |x| [x, Telegram::Bot::Types.const_get(x.camelize)] }.to_h.
      merge(
        'chat_member' => Telegram::Bot::Types::ChatMemberUpdated
      )
    unique_types.each do |type, type_class|
      context "with #{type}" do
        let(:payload_type) { type }
        let(:payload) do
          {}.tap do |result|
            result[:chat] = chat if type_class.instance_methods.include?(:chat)
            result[:from] = from if type_class.instance_methods.include?(:from)
          end
        end
        let(:chat) { {id: 'chat_id'} }
        let(:from) { {id: 'from_id'} }
        its(:payload_type) { should eq payload_type }
        its(:payload) { should be_instance_of type_class }

        if type_class.instance_methods.include?(:chat)
          # Virtus does not support ==. :(
          its(:chat) { should be_instance_of Telegram::Bot::Types::Chat }
          its('chat.to_hash') { should include chat }
        else
          its(:chat) { should eq nil }
        end

        if type_class.instance_methods.include?(:from)
          its(:from) { should be_instance_of Telegram::Bot::Types::User }
          its('from.to_hash') { should include from }
        else
          its(:from) { should eq nil }
        end
      end
    end
  end
end
