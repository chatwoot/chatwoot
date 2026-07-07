require 'rails_helper'

RSpec.describe Telegram::ReactionService do
  let!(:telegram_channel) { create(:channel_telegram) }
  let!(:inbox) { telegram_channel.inbox }
  let!(:contact) { create(:contact, account: telegram_channel.account) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '111') }
  let!(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox) }
  let!(:target_message) { create(:message, conversation: conversation, source_id: '555') }

  let(:base_params) do
    {
      'update_id' => 987_654_321,
      'message_reaction' => {
        'chat' => { 'id' => 111 },
        'message_id' => 555,
        'user' => { 'id' => 111, 'first_name' => 'Jane', 'last_name' => 'Doe' },
        'date' => Time.current.to_i,
        'old_reaction' => [],
        'new_reaction' => [{ 'type' => 'emoji', 'emoji' => '👍' }]
      }
    }.with_indifferent_access
  end

  describe '#perform' do
    context 'when the target message exists and the reaction is a supported emoji' do
      it 'creates a MessageReaction without creating a new message' do
        expect { described_class.new(inbox: inbox, params: base_params).perform }
          .to change(MessageReaction, :count).by(1)
          .and not_change(Message, :count)

        reaction = MessageReaction.last
        expect(reaction.message).to eq(target_message)
        expect(reaction.emoji).to eq('👍')
        expect(reaction.reaction_type).to eq('emoji')
        expect(reaction.status).to eq('active')
        expect(reaction.actor_external_id).to eq('111')
        expect(reaction.sender).to eq(contact)
      end
    end

    context 'when new_reaction is empty (unreact)' do
      let(:unreact_params) do
        base_params.deep_dup.tap do |params|
          params['update_id'] = 987_654_322
          params['message_reaction']['new_reaction'] = []
        end
      end

      it 'marks the existing reaction as removed without creating a new message or reaction row' do
        described_class.new(inbox: inbox, params: base_params).perform
        reaction = MessageReaction.last
        expect(reaction.status).to eq('active')

        expect { described_class.new(inbox: inbox, params: unreact_params).perform }
          .not_to change(MessageReaction, :count)

        expect(reaction.reload.status).to eq('removed')
      end
    end

    context 'when the reaction type is unsupported (e.g. paid)' do
      let(:unsupported_params) do
        base_params.deep_dup.tap do |params|
          params['message_reaction']['new_reaction'] = [{ 'type' => 'paid' }]
        end
      end

      it 'logs a warning and does not create a reaction or a contact' do
        expect(Rails.logger).to receive(:warn)

        expect { described_class.new(inbox: inbox, params: unsupported_params).perform }
          .not_to change(MessageReaction, :count)

        expect(Contact.where(account: telegram_channel.account).count).to eq(1)
      end
    end

    context 'when the target message does not exist' do
      let(:missing_target_params) do
        base_params.deep_dup.tap do |params|
          params['message_reaction']['message_id'] = 999_999
          params['message_reaction']['user'] = { 'id' => 222_222, 'first_name' => 'New', 'last_name' => 'Person' }
        end
      end

      it 'does not create a contact, conversation, message, or reaction' do
        expect(Rails.logger).to receive(:warn)

        expect { described_class.new(inbox: inbox, params: missing_target_params).perform }
          .not_to change(MessageReaction, :count)

        expect(Contact.where(account: telegram_channel.account).count).to eq(1)
        expect(inbox.messages.count).to eq(1)
      end
    end

    context 'when the actor is an anonymous/channel actor_chat instead of a user' do
      let(:actor_chat_params) do
        base_params.deep_dup.tap do |params|
          params['message_reaction'].delete('user')
          params['message_reaction']['actor_chat'] = { 'id' => 333_333, 'title' => 'Some Channel' }
        end
      end

      it 'resolves the contact from actor_chat and creates the reaction' do
        expect { described_class.new(inbox: inbox, params: actor_chat_params).perform }
          .to change(MessageReaction, :count).by(1)

        reaction = MessageReaction.last
        expect(reaction.actor_external_id).to eq('333333')
        expect(reaction.sender.name).to eq('Some Channel')
      end
    end
  end
end
