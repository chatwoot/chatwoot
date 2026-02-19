# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Conversations::AutoLabelPendingConversationsJob do
  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  context 'when there are eligible conversations' do
    it 'enqueues AutoAssignConversationJob for eligible conversations' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago)
      create(:message, conversation: conversation, message_type: :incoming)

      expect { described_class.perform_now }
        .to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when conversation already has max labels' do
    it 'does not enqueue job for conversations with 2 labels' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago,
                                           cached_label_list: 'label1, label2')
      create(:message, conversation: conversation, message_type: :incoming)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when conversation has only 1 label' do
    it 'enqueues job for conversations that can still receive another label' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago,
                                           cached_label_list: 'existing_label')
      create(:message, conversation: conversation, message_type: :incoming)

      expect { described_class.perform_now }
        .to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when conversation has no incoming messages' do
    it 'does not enqueue job for conversations without incoming messages' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago)
      create(:message, conversation: conversation, message_type: :outgoing)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when account has no auto-assign labels' do
    it 'does not enqueue job for accounts without auto-assign labels' do
      account = create(:account)
      conversation = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago)
      create(:message, conversation: conversation, message_type: :incoming)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when conversation was already triaged with no new messages' do
    it 'does not enqueue job for already-triaged conversations' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago)
      create(:message, conversation: conversation, message_type: :incoming, created_at: 8.minutes.ago)
      conversation.update_column(:last_triaged_at, 5.minutes.ago)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when conversation was triaged but has new messages since' do
    it 'enqueues job for conversations with new incoming messages' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago)
      create(:message, conversation: conversation, message_type: :incoming, created_at: 8.minutes.ago)
      conversation.update_column(:last_triaged_at, 6.minutes.ago)
      # New message after triage
      create(:message, conversation: conversation, message_type: :incoming, created_at: 2.minutes.ago)

      expect { described_class.perform_now }
        .to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when conversation is older than 24 hours' do
    it 'does not enqueue job for old conversations' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 25.hours.ago)
      create(:message, conversation: conversation, message_type: :incoming)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when there are more conversations than BATCH_LIMIT' do
    it 'only enqueues up to BATCH_LIMIT conversations' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)

      55.times do
        conv = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago)
        create(:message, conversation: conv, message_type: :incoming)
      end

      described_class.perform_now

      expect(AutoAssignConversationJob).to have_been_enqueued.exactly(50).times
    end
  end
end
