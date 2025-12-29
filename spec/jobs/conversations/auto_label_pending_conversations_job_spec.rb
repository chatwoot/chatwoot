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

  context 'when conversation already has labels' do
    it 'does not enqueue job for conversations with labels' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 10.minutes.ago,
                                           cached_label_list: 'existing_label')
      create(:message, conversation: conversation, message_type: :incoming)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(AutoAssignConversationJob)
        .with(conversation.id)
    end
  end

  context 'when conversation is less than 5 minutes old' do
    it 'does not enqueue job for recent conversations' do
      account = create(:account)
      create(:label, account: account, allow_auto_assign: true)
      conversation = create(:conversation, account: account, status: :open, created_at: 2.minutes.ago)
      create(:message, conversation: conversation, message_type: :incoming)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(AutoAssignConversationJob)
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
end
