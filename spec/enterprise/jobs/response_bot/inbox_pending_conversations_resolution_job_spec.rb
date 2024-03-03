require 'rails_helper'

RSpec.describe ResponseBot::InboxPendingConversationsResolutionJob, type: :job do
  include ActiveJob::TestHelper

  let!(:inbox) { create(:inbox) }
  let!(:resolvable_pending_conversation) { create(:conversation, inbox: inbox, last_activity_at: 2.hours.ago, status: :pending) }
  let!(:recent_pending_conversation) { create(:conversation, inbox: inbox, last_activity_at: 10.minutes.ago, status: :pending) }
  let!(:open_conversation) { create(:conversation, inbox: inbox, last_activity_at: 1.hour.ago, status: :open) }

  before do
    stub_const('Limits::BULK_ACTIONS_LIMIT', 2)
  end

  it 'queues the job' do
    expect { described_class.perform_later(inbox) }
      .to have_enqueued_job.on_queue('low')
  end

  it 'resolves only the eligible pending conversations' do
    perform_enqueued_jobs { described_class.perform_later(inbox) }

    expect(resolvable_pending_conversation.reload.status).to eq('resolved')
    expect(recent_pending_conversation.reload.status).to eq('pending')
    expect(open_conversation.reload.status).to eq('open')
  end

  it 'creates an outgoing message for each resolved conversation' do
    # resolution message + system message
    expect { perform_enqueued_jobs { described_class.perform_later(inbox) } }
      .to change { resolvable_pending_conversation.messages.reload.count }.by(2)

    resolved_conversation_messages = resolvable_pending_conversation.messages.map(&:content)
    expect(resolved_conversation_messages).to include(
      'Resolving the conversation as it has been inactive for a while. Please start a new conversation if you need further assistance.'
    )
  end
end
