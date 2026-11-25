require 'rails_helper'

RSpec.describe Captain::ReplySuggestionJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:service) { instance_double(Captain::ReplySuggestionService) }

  before do
    allow(Captain::ReplySuggestionService).to receive(:new)
      .with(account: account, conversation_display_id: conversation.display_id, user: user).and_return(service)
  end

  def perform
    described_class.perform_now(account: account, user: user, conversation_display_id: conversation.display_id, request_id: 'req-1')
  end

  it 'sends the draft to the requesting agent only, with the request and conversation' do
    allow(service).to receive(:perform).and_return({ message: 'Here is how.', follow_up_context: { 'event_name' => 'reply_suggestion' } })

    expect { perform }.to have_enqueued_job(ActionCableBroadcastJob).with(
      [user.pubsub_token],
      described_class::EVENT_NAME,
      { account_id: account.id, conversation_id: conversation.display_id, request_id: 'req-1', message: 'Here is how.',
        follow_up_context: { 'event_name' => 'reply_suggestion' } }
    )
  end

  it 'sends the reason when no reply is needed' do
    allow(service).to receive(:perform).and_return({ message: nil, no_reply_reason: 'You already answered.' })

    expect { perform }.to have_enqueued_job(ActionCableBroadcastJob).with(
      [user.pubsub_token], described_class::EVENT_NAME, hash_including(no_reply_reason: 'You already answered.', request_id: 'req-1')
    )
  end

  it 'reports an unexpected failure and still tells the agent' do
    allow(service).to receive(:perform).and_raise(StandardError, 'boom')
    tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)

    expect { perform }.to have_enqueued_job(ActionCableBroadcastJob).with(
      [user.pubsub_token], described_class::EVENT_NAME, hash_including(error: I18n.t('captain.reply_suggestion.failed'))
    )
    expect(tracker).to have_received(:capture_exception)
  end
end
