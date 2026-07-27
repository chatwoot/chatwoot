require 'rails_helper'

RSpec.describe Messages::RetryService do
  let(:account) { create(:account) }
  let(:inbox) { create(:channel_email, account: account).inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) do
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      status: :failed,
      message_type: :outgoing,
      content_attributes: { external_error: 'SMTP unavailable', email: { subject: 'Hello' } }
    )
  end

  before { clear_enqueued_jobs }

  it 'resets and immediately enqueues a failed message' do
    expect { described_class.new(message).perform }
      .to have_enqueued_job(SendReplyJob).with(message.id)

    expect(message.reload).to be_sent
    expect(message.content_attributes).to eq({})
  end

  it 'supports a delayed retry' do
    travel_to Time.zone.parse('2026-07-26 12:00:00 UTC') do
      expect { described_class.new(message, wait: 10.minutes).perform }
        .to have_enqueued_job(SendReplyJob).with(message.id).at(10.minutes.from_now)
    end
  end

  it 'does not enqueue a message that is no longer failed' do
    message.update!(status: :sent)
    result = nil

    expect { result = described_class.new(message).perform }.not_to have_enqueued_job(SendReplyJob)
    expect(result).to be(false)
  end

  it 'restores the failed state when enqueueing raises an error' do
    original_attributes = message.content_attributes.deep_dup
    allow(SendReplyJob).to receive(:perform_later).and_raise(ActiveJob::EnqueueError, 'Redis unavailable')

    travel_to Time.zone.parse('2026-07-27 12:00:00.123456789 UTC'), with_usec: true do
      expect { described_class.new(message).perform }
        .to raise_error(ActiveJob::EnqueueError, 'Redis unavailable')
    end

    expect(message.reload).to be_failed
    expect(message.content_attributes).to eq(original_attributes)
  end
end
