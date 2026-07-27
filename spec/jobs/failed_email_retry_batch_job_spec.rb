require 'rails_helper'

RSpec.describe FailedEmailRetryBatchJob do
  let(:active_account) { create(:account) }
  let(:active_inbox) { create(:channel_email, account: active_account).inbox }
  let(:suspended_account) { create(:account, status: :suspended) }
  let(:suspended_inbox) { create(:channel_email, account: suspended_account).inbox }
  let!(:active_message) do
    create(
      :message,
      account: active_account,
      inbox: active_inbox,
      conversation: create(:conversation, account: active_account, inbox: active_inbox),
      status: :failed,
      message_type: :outgoing
    )
  end
  let!(:suspended_message) do
    create(
      :message,
      account: suspended_account,
      inbox: suspended_inbox,
      conversation: create(:conversation, account: suspended_account, inbox: suspended_inbox),
      status: :failed,
      message_type: :outgoing
    )
  end
  let(:batch) do
    create(
      :failed_email_retry_batch,
      range_start: 1.hour.ago,
      range_end: Time.current,
      candidate_count: 2,
      eligible_count: 1
    )
  end

  before do
    active_message
    suspended_message
    clear_enqueued_jobs
  end

  it 'schedules eligible messages with jitter and skips suspended accounts' do
    scheduling_started_at = Time.current
    described_class.perform_now(batch.id)

    send_reply_job = enqueued_jobs.find { |job| job[:job] == SendReplyJob }
    expect(send_reply_job[:at]).to be_between(
      (scheduling_started_at + 1.minute).to_f,
      (scheduling_started_at + 2.hours + 1.second).to_f
    )

    expect(batch.reload).to be_completed
    expect(batch).to have_attributes(scheduled_count: 1, skipped_count: 1, error_count: 0)
    expect(active_message.reload).to be_sent
    expect(suspended_message.reload).to be_failed
  end

  it 'continues scheduling after an individual message error' do
    second_message = create(
      :message,
      account: active_account,
      inbox: active_inbox,
      conversation: create(:conversation, account: active_account, inbox: active_inbox),
      status: :failed,
      message_type: :outgoing
    )
    batch.update!(candidate_count: 3, eligible_count: 2, range_end: Time.current)
    failing_service = instance_double(Messages::RetryService)
    allow(failing_service).to receive(:perform).and_raise(ActiveJob::EnqueueError, 'Redis unavailable')
    allow(Messages::RetryService).to receive(:new).and_call_original
    allow(Messages::RetryService).to receive(:new)
      .with(active_message, wait: kind_of(ActiveSupport::Duration))
      .and_return(failing_service)

    described_class.perform_now(batch.id)

    expect(batch.reload).to be_completed
    expect(batch).to have_attributes(scheduled_count: 1, skipped_count: 1, error_count: 1)
    expect(active_message.reload).to be_failed
    expect(second_message.reload).to be_sent
  end

  it 'counts messages retried before processing as skipped' do
    active_message.update!(status: :sent)

    described_class.perform_now(batch.id)

    expect(batch.reload).to have_attributes(status: 'completed', scheduled_count: 0, skipped_count: 2, error_count: 0)
  end

  it 'marks the batch failed when processing stops unexpectedly' do
    allow(FailedEmailRetryBatch).to receive(:find_by).with(id: batch.id).and_return(batch)
    allow(batch).to receive(:candidates).and_raise(ActiveRecord::StatementInvalid, 'database unavailable')

    described_class.perform_now(batch.id)

    expect(batch.reload).to be_failed
    expect(batch.error_message).to eq(I18n.t('super_admin.failed_email_retries.batch_failed'))
  end

  it 'does not process a batch that has already been claimed' do
    batch.update!(status: :processing)

    expect { described_class.perform_now(batch.id) }.not_to have_enqueued_job(SendReplyJob)
    expect(active_message.reload).to be_failed
  end

  it 'uses inclusive jitter bounds from one minute through two hours' do
    job = described_class.new

    allow(job).to receive(:rand).with(1.minute.to_i..2.hours.to_i).and_return(1.minute.to_i, 2.hours.to_i)

    expect(job.send(:retry_delay)).to eq(1.minute)
    expect(job.send(:retry_delay)).to eq(2.hours)
  end
end
