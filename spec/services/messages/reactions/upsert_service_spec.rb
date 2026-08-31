# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Reactions::UpsertService do
  let(:message) { create(:message, message_type: :outgoing, source_id: 'provider-message-id') }
  let(:account) { message.account }
  let(:inbox) { message.inbox }
  let(:conversation) { message.conversation }
  let(:contact) { conversation.contact }
  let(:dispatcher) { Rails.configuration.dispatcher }
  let(:reaction_events) do
    [Events::Types::MESSAGE_REACTION_CREATED, Events::Types::MESSAGE_REACTION_UPDATED, Events::Types::MESSAGE_REACTION_REMOVED]
  end

  def perform_service(overrides = {})
    described_class.new(account: account,
                        inbox: inbox,
                        conversation: conversation,
                        message: message,
                        sender: contact,
                        actor_external_id: 'wa-contact-1',
                        source_id: 'reaction-event-1',
                        external_message_id: 'provider-message-id',
                        emoji: '👍',
                        reaction_type: 'emoji',
                        action: :react,
                        external_created_at: Time.current, **overrides).perform
  end

  # Force all the fixtures (message/account/inbox/conversation/contact) to be created up front so
  # that factory side effects (e.g. MESSAGE_CREATED dispatch) don't get counted as part of the
  # `expect { ... }.to change(...)` / dispatch-call assertions below, which only care about what
  # the service under test does.
  before do
    message
    account
    inbox
    conversation
    contact
    allow(dispatcher).to receive(:dispatch).and_call_original
  end

  describe '#perform' do
    it 'creates an active incoming reaction without creating a message' do
      message_count_before = Message.count

      expect { perform_service }.to change(MessageReaction, :count).by(1)
      expect(Message.count).to eq(message_count_before)

      reaction = MessageReaction.last
      expect(reaction).to have_attributes(
        message_id: message.id,
        conversation_id: conversation.id,
        account_id: account.id,
        inbox_id: inbox.id,
        sender: contact,
        direction: 'incoming',
        status: 'active',
        emoji: '👍',
        reaction_type: 'emoji',
        source_id: 'reaction-event-1',
        external_message_id: 'provider-message-id'
      )
    end

    it 'dispatches a MESSAGE_REACTION_CREATED event with the expected payload' do
      perform_service

      expect(dispatcher).to have_received(:dispatch).with(
        Events::Types::MESSAGE_REACTION_CREATED,
        kind_of(Time),
        hash_including(
          message_reaction: an_instance_of(MessageReaction),
          message: message,
          conversation: conversation,
          account: account,
          inbox: inbox,
          sender: contact
        )
      )
    end

    it 'bumps conversation last_activity_at' do
      # rubocop:disable Rails/SkipsModelValidations
      conversation.update_columns(last_activity_at: 2.days.ago)
      # rubocop:enable Rails/SkipsModelValidations

      expect { perform_service }.to(change { conversation.reload.last_activity_at })
    end

    it 'does not update waiting_since' do
      conversation.update!(waiting_since: 2.hours.ago)
      waiting_since = conversation.waiting_since

      perform_service

      expect(conversation.reload.waiting_since.to_i).to eq(waiting_since.to_i)
    end

    it 'is idempotent for a duplicate source_id (webhook retry)' do
      first = perform_service

      expect do
        second = perform_service
        expect(second.id).to eq(first.id)
      end.not_to change(MessageReaction, :count)

      reaction_events.each do |event|
        expected_times = event == Events::Types::MESSAGE_REACTION_CREATED ? 1 : 0
        expect(dispatcher).to have_received(:dispatch).with(event, anything, anything).exactly(expected_times).times
      end
    end

    it 'updates the existing row in place when the same actor changes emoji (new source_id)' do
      first = perform_service(source_id: 'reaction-event-1', emoji: '👍')

      expect do
        perform_service(source_id: 'reaction-event-2', emoji: '❤️')
      end.not_to change(MessageReaction, :count)

      first.reload
      expect(first.emoji).to eq('❤️')
      expect(first.source_id).to eq('reaction-event-2')

      expect(dispatcher).to have_received(:dispatch).with(
        Events::Types::MESSAGE_REACTION_UPDATED,
        kind_of(Time),
        hash_including(message_reaction: first)
      ).once
    end

    it 'marks the reaction removed on action: :unreact and dispatches MESSAGE_REACTION_REMOVED' do
      created = perform_service(source_id: 'reaction-event-1', action: :react)

      perform_service(source_id: 'reaction-event-2', action: :unreact)
      created.reload

      expect(created.status).to eq('removed')
      expect(dispatcher).to have_received(:dispatch).with(
        Events::Types::MESSAGE_REACTION_REMOVED,
        kind_of(Time),
        hash_including(message_reaction: created)
      ).once
    end

    it 'does not re-dispatch when unreact is called again on an already-removed reaction' do
      perform_service(source_id: 'reaction-event-1', action: :react)
      perform_service(source_id: 'reaction-event-2', action: :unreact)

      expect do
        perform_service(source_id: 'reaction-event-3', action: :unreact)
      end.not_to change(MessageReaction, :count)

      expect(dispatcher).to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_REMOVED, anything, anything).once
    end

    it 'reactivates the same row on react after unreact and dispatches MESSAGE_REACTION_UPDATED' do
      created = perform_service(source_id: 'reaction-event-1', action: :react)
      perform_service(source_id: 'reaction-event-2', action: :unreact)

      expect do
        perform_service(source_id: 'reaction-event-3', action: :react, emoji: '👍')
      end.not_to change(MessageReaction, :count)

      created.reload
      expect(created.status).to eq('active')

      expect(dispatcher).to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_CREATED, anything, anything).once
      expect(dispatcher).to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_REMOVED, anything, anything).once
      expect(dispatcher).to have_received(:dispatch).with(
        Events::Types::MESSAGE_REACTION_UPDATED,
        kind_of(Time),
        hash_including(message_reaction: created)
      ).once
    end

    it 'does not re-dispatch for a true duplicate react (same emoji, same status, new source_id)' do
      perform_service(source_id: 'reaction-event-1', emoji: '👍')

      expect do
        perform_service(source_id: 'reaction-event-2', emoji: '👍')
      end.not_to change(MessageReaction, :count)

      expect(dispatcher).to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_CREATED, anything, anything).once
      expect(dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGE_REACTION_UPDATED, anything, anything)
    end

    it 'fails without side effects when the message belongs to a different account' do
      other_account = create(:account)

      expect do
        result = described_class.new(
          account: other_account,
          inbox: inbox,
          conversation: conversation,
          message: message,
          sender: contact,
          actor_external_id: 'wa-contact-1',
          source_id: 'reaction-event-1',
          external_message_id: 'provider-message-id',
          emoji: '👍',
          reaction_type: 'emoji',
          action: :react,
          external_created_at: Time.current
        ).perform

        expect(result).to be_nil
      end.not_to change(MessageReaction, :count)

      expect(dispatcher).not_to have_received(:dispatch).with(anything, anything, hash_including(:message_reaction))
    end
  end
end
