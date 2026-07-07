require 'rails_helper'

RSpec.describe Instagram::ReactionService do
  let!(:channel) { create(:channel_instagram, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:inbox) { channel.inbox }
  let(:source_id) { 'Sender-id-1' }
  let!(:contact) { create(:contact, account: channel.account) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: source_id) }
  let!(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox) }
  let!(:target_message) { create(:message, conversation: conversation, source_id: 'message-id-to-react-to') }

  let(:base_params) do
    {
      'sender' => { 'id' => source_id },
      'recipient' => { 'id' => channel.instagram_id },
      'timestamp' => Time.current.to_i * 1000,
      'reaction' => {
        'mid' => target_message.source_id,
        'action' => 'react',
        'reaction' => 'love',
        'emoji' => '❤️'
      }
    }.with_indifferent_access
  end

  describe '#perform' do
    context 'when the target message exists' do
      it 'creates a MessageReaction without creating a new message' do
        expect { described_class.new(params: base_params, channel: channel).perform }
          .to change(MessageReaction, :count).by(1)
          .and not_change(Message, :count)

        reaction = MessageReaction.last
        expect(reaction.message).to eq(target_message)
        expect(reaction.emoji).to eq('❤️')
        expect(reaction.reaction_type).to eq('love')
        expect(reaction.status).to eq('active')
        expect(reaction.actor_external_id).to eq(source_id)
        expect(reaction.sender).to eq(contact)
      end
    end

    context 'when action is unreact' do
      let(:unreact_params) do
        base_params.deep_dup.tap do |params|
          params['timestamp'] = 1.second.from_now.to_i * 1000
          params['reaction']['action'] = 'unreact'
          params['reaction']['emoji'] = nil
        end
      end

      it 'marks the existing reaction as removed without creating a new message or reaction row' do
        described_class.new(params: base_params, channel: channel).perform
        reaction = MessageReaction.last
        expect(reaction.status).to eq('active')

        expect { described_class.new(params: unreact_params, channel: channel).perform }
          .not_to change(MessageReaction, :count)

        expect(reaction.reload.status).to eq('removed')
      end
    end

    context 'when the target message does not exist' do
      let(:missing_target_params) do
        base_params.deep_dup.tap do |params|
          params['sender']['id'] = 'New-sender-id'
          params['reaction']['mid'] = 'missing-message-id'
        end
      end

      it 'does not create a contact, conversation, message, or reaction' do
        expect(Rails.logger).to receive(:warn)

        expect { described_class.new(params: missing_target_params, channel: channel).perform }
          .to not_change(Contact, :count)
          .and not_change(ContactInbox, :count)
          .and not_change(Conversation, :count)
          .and not_change(Message, :count)
          .and not_change(MessageReaction, :count)
      end
    end
  end
end
