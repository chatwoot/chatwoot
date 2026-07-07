# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Facebook::MessageCreator do
  before do
    stub_request(:post, /graph.facebook.com/)
  end

  let!(:channel) { create(:channel_facebook_page) }
  let(:inbox) { channel.inbox }
  let(:source_id) { 'Sender-id-1' }
  let!(:contact) { create(:contact, account: channel.account) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: source_id) }
  let!(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox, account: channel.account) }
  let!(:target_message) { create(:message, account: channel.account, inbox: inbox, conversation: conversation, source_id: 'message-id-to-react-to') }

  let(:base_payload) do
    {
      'messaging' => {
        'sender' => { 'id' => source_id },
        'recipient' => { 'id' => channel.page_id },
        'timestamp' => Time.current.to_i * 1000,
        'reaction' => {
          'mid' => target_message.source_id,
          'action' => 'react',
          'reaction' => 'like',
          'emoji' => '👍'
        }
      }
    }.to_json
  end

  describe '#perform' do
    it 'creates a MessageReaction without creating a new message' do
      parser = Integrations::Facebook::MessageParser.new(base_payload)

      expect { described_class.new(parser).perform }
        .to change(MessageReaction, :count).by(1)
        .and not_change(Message, :count)

      reaction = MessageReaction.last
      expect(reaction).to have_attributes(
        message: target_message,
        emoji: '👍',
        reaction_type: 'like',
        status: 'active',
        actor_external_id: source_id,
        sender: contact,
        external_message_id: target_message.source_id
      )
      expect(reaction.external_created_at.to_i).to eq(parser.time_stamp / 1000)
    end

    it 'returns before building a timeline message' do
      parser = Integrations::Facebook::MessageParser.new(base_payload)

      expect(Messages::Facebook::MessageBuilder).not_to receive(:new)

      described_class.new(parser).perform
    end

    context 'when action is unreact' do
      let(:unreact_payload) do
        JSON.parse(base_payload).tap do |payload|
          payload['messaging']['timestamp'] = 1.second.from_now.to_i * 1000
          payload['messaging']['reaction']['action'] = 'unreact'
          payload['messaging']['reaction']['emoji'] = nil
        end.to_json
      end

      it 'marks the existing reaction as removed without creating a new message or reaction row' do
        described_class.new(Integrations::Facebook::MessageParser.new(base_payload)).perform
        reaction = MessageReaction.last
        expect(reaction.status).to eq('active')

        expect { described_class.new(Integrations::Facebook::MessageParser.new(unreact_payload)).perform }
          .not_to change(MessageReaction, :count)

        expect(reaction.reload.status).to eq('removed')
      end
    end

    context 'when the target message does not exist' do
      let(:missing_target_payload) do
        JSON.parse(base_payload).tap do |payload|
          payload['messaging']['sender']['id'] = 'New-sender-id'
          payload['messaging']['reaction']['mid'] = 'missing-message-id'
        end.to_json
      end

      it 'does not create a contact, conversation, message, or reaction' do
        parser = Integrations::Facebook::MessageParser.new(missing_target_payload)
        expect(Rails.logger).to receive(:warn)

        expect { described_class.new(parser).perform }
          .to not_change(Contact, :count)
          .and not_change(ContactInbox, :count)
          .and not_change(Conversation, :count)
          .and not_change(Message, :count)
          .and not_change(MessageReaction, :count)
      end
    end

    context 'when the reaction target message id is blank' do
      let(:nil_source_message) { create(:message, account: channel.account, inbox: inbox, conversation: conversation, source_id: nil) }

      let(:blank_target_payload) do
        JSON.parse(base_payload).tap do |payload|
          payload['messaging']['sender']['id'] = 'New-sender-id'
          payload['messaging']['reaction'].delete('mid')
        end.to_json
      end

      it 'does not create a contact, conversation, message, or reaction' do
        nil_source_message
        parser = Integrations::Facebook::MessageParser.new(blank_target_payload)
        expect(Rails.logger).to receive(:warn)

        expect { described_class.new(parser).perform }
          .to not_change(Contact, :count)
          .and not_change(ContactInbox, :count)
          .and not_change(Conversation, :count)
          .and not_change(Message, :count)
          .and not_change(MessageReaction, :count)
      end
    end

    context 'when another inbox has a message with the same source id' do
      let!(:other_channel) { create(:channel_facebook_page) }
      let!(:other_contact) { create(:contact, account: other_channel.account) }
      let!(:other_contact_inbox) { create(:contact_inbox, contact: other_contact, inbox: other_channel.inbox, source_id: source_id) }
      let!(:other_conversation) do
        create(:conversation, contact: other_contact, inbox: other_channel.inbox, contact_inbox: other_contact_inbox, account: other_channel.account)
      end
      let!(:other_target_message) do
        create(:message, account: other_channel.account, inbox: other_channel.inbox, conversation: other_conversation,
                         source_id: 'shared-provider-message-id')
      end
      let!(:target_message) do
        create(:message, account: channel.account, inbox: inbox, conversation: conversation, source_id: other_target_message.source_id)
      end

      it 'attaches the reaction to the message in the webhook recipient inbox' do
        parser = Integrations::Facebook::MessageParser.new(base_payload)

        described_class.new(parser).perform

        reaction = MessageReaction.last
        expect(reaction.message).to eq(target_message)
        expect(reaction.inbox).to eq(inbox)
        expect(reaction.message).not_to eq(other_target_message)
      end
    end
  end
end
