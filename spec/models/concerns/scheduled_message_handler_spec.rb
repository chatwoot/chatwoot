require 'rails_helper'

RSpec.describe ScheduledMessageHandler do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  let(:scheduled_message) do
    create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: author)
  end

  let(:message) do
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: :outgoing,
      additional_attributes: { 'scheduled_message_id' => scheduled_message.id }
    )
  end

  describe '#update_scheduled_message_status' do
    it 'marks scheduled message as sent when message status changes to delivered' do
      message.update!(status: :delivered)
      expect(scheduled_message.reload.status).to eq('sent')
    end

    it 'marks scheduled message as sent when message status changes to read' do
      message.update!(status: :read)
      expect(scheduled_message.reload.status).to eq('sent')
    end

    it 'marks scheduled message as failed when message status changes to failed' do
      message.update!(status: :failed)
      expect(scheduled_message.reload.status).to eq('failed')
    end

    it 'does not raise an error when message has no scheduled_message_id' do
      message_without_scheduled = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        message_type: :outgoing
      )

      expect { message_without_scheduled.update!(status: :delivered) }.not_to raise_error
    end
  end

  describe '#dispatch_scheduled_message_update' do
    it 'dispatches SCHEDULED_MESSAGE_UPDATED event when scheduled message status is updated' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original

      expect(Rails.configuration.dispatcher).to receive(:dispatch)
        .with(Events::Types::SCHEDULED_MESSAGE_UPDATED, anything, scheduled_message: scheduled_message)

      message.update!(status: :delivered)
    end

    it 'does not dispatch SCHEDULED_MESSAGE_UPDATED event when scheduled message status is not updated' do
      expect(Rails.configuration.dispatcher).not_to receive(:dispatch)
        .with(Events::Types::SCHEDULED_MESSAGE_UPDATED, anything, anything)

      message.update!(content: 'Updated content')
    end
  end

  describe '#hold_pending_scheduled_messages' do
    let(:pending_with_flag) do
      create(:scheduled_message,
             account: account, inbox: inbox, conversation: conversation,
             author: author, hold_on_reply: true,
             scheduled_at: 1.hour.from_now, status: :pending)
    end

    let(:pending_without_flag) do
      create(:scheduled_message,
             account: account, inbox: inbox, conversation: conversation,
             author: author, hold_on_reply: false,
             scheduled_at: 1.hour.from_now, status: :pending)
    end

    it 'holds pending scheduled messages with hold_on_reply when customer sends a message' do
      pending_with_flag

      create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)

      expect(pending_with_flag.reload.status).to eq('held')
    end

    it 'does not hold pending messages without hold_on_reply flag' do
      pending_without_flag

      create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)

      expect(pending_without_flag.reload.status).to eq('pending')
    end

    it 'does not hold messages when customer sends a reaction' do
      pending_with_flag

      create(:message, account: account, inbox: inbox, conversation: conversation,
                       message_type: :incoming,
                       content_attributes: { 'is_reaction' => true })

      expect(pending_with_flag.reload.status).to eq('pending')
    end

    it 'does not hold messages when an outgoing message is sent by the agent' do
      pending_with_flag

      create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing)

      expect(pending_with_flag.reload.status).to eq('pending')
    end

    it 'does not hold messages on private notes' do
      pending_with_flag

      create(:message, account: account, inbox: inbox, conversation: conversation,
                       message_type: :incoming, private: true)

      expect(pending_with_flag.reload.status).to eq('pending')
    end

    it 'dispatches SCHEDULED_MESSAGE_UPDATED event for each held message' do
      pending_with_flag

      allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original

      expect(Rails.configuration.dispatcher).to receive(:dispatch)
        .with(Events::Types::SCHEDULED_MESSAGE_UPDATED, anything, scheduled_message: pending_with_flag)
        .at_least(:once)

      create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)
    end

    context 'when the held message belongs to a recurring series' do
      let(:recurring) do
        create(:recurring_scheduled_message,
               account: account, inbox: inbox, conversation: conversation,
               author: author, hold_on_reply: true, status: :active)
      end

      let(:recurring_occurrence) do
        create(:scheduled_message,
               account: account, inbox: inbox, conversation: conversation,
               author: author, hold_on_reply: true, status: :pending,
               scheduled_at: 1.hour.from_now,
               recurring_scheduled_message: recurring)
      end

      it 'holds the occurrence and detaches it from the series' do
        recurring_occurrence

        create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)

        expect(recurring_occurrence.reload.status).to eq('held')
        expect(recurring_occurrence.reload.recurring_scheduled_message_id).to be_nil
      end

      it 'creates a new pending occurrence linked to the series' do
        recurring_occurrence

        expect do
          create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)
        end.to change(ScheduledMessage, :count).by(1)

        new_occurrence = recurring.scheduled_messages.pending.first
        expect(new_occurrence).to be_present
        expect(new_occurrence.id).not_to eq(recurring_occurrence.id)
      end
    end
  end
end
