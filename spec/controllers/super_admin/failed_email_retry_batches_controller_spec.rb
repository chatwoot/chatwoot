require 'rails_helper'

RSpec.describe 'Super Admin Failed Email Retry Batches', type: :request do
  let(:super_admin) { create(:super_admin) }
  let(:account) { create(:account) }
  let(:inbox) { create(:channel_email, account: account).inbox }
  let!(:failed_message) do
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: create(:conversation, account: account, inbox: inbox),
      status: :failed,
      message_type: :outgoing
    )
  end

  before do
    failed_message
    clear_enqueued_jobs
  end

  describe 'POST /super_admin/failed_email_retry_batches' do
    it 'redirects an unauthenticated super admin' do
      post '/super_admin/failed_email_retry_batches', params: { lookback_hours: 1 }

      expect(response).to have_http_status(:redirect)
      expect(FailedEmailRetryBatch).not_to exist
    end

    it 'recomputes the snapshot and queues a batch' do
      sign_in(super_admin, scope: :super_admin)

      expect do
        post '/super_admin/failed_email_retry_batches',
             params: { lookback_hours: 1, candidate_count: 99, eligible_count: 99 }
      end.to change(FailedEmailRetryBatch, :count).by(1)
      expect(FailedEmailRetryBatchJob).to have_been_enqueued

      batch = FailedEmailRetryBatch.last
      expect(batch).to have_attributes(
        requested_by: super_admin,
        lookback_hours: 1,
        candidate_count: 1,
        eligible_count: 1,
        status: 'queued'
      )
      expect(response).to redirect_to(
        super_admin_app_config_path(
          config: 'internal',
          lookback_hours: 1,
          failed_email_retry_batch_id: batch.id
        )
      )
    end

    it 'rejects an unsupported lookback period' do
      sign_in(super_admin, scope: :super_admin)

      expect do
        post '/super_admin/failed_email_retry_batches', params: { lookback_hours: 3 }
      end.not_to change(FailedEmailRetryBatch, :count)

      expect(response).to redirect_to(super_admin_app_config_path(config: 'internal'))
    end

    it 'does not create a batch without eligible messages' do
      failed_message.update!(status: :sent)
      sign_in(super_admin, scope: :super_admin)

      expect do
        post '/super_admin/failed_email_retry_batches', params: { lookback_hours: 1 }
      end.not_to change(FailedEmailRetryBatch, :count)

      expect(response).to redirect_to(super_admin_app_config_path(config: 'internal', lookback_hours: 1))
    end

    it 'marks a created batch failed when it cannot enqueue the processor' do
      sign_in(super_admin, scope: :super_admin)
      allow(FailedEmailRetryBatchJob).to receive(:perform_later).and_raise(ActiveJob::EnqueueError, 'Redis unavailable')

      expect do
        post '/super_admin/failed_email_retry_batches', params: { lookback_hours: 1 }
      end.to change(FailedEmailRetryBatch, :count).by(1)

      expect(FailedEmailRetryBatch.last).to have_attributes(
        status: 'failed',
        error_message: I18n.t('super_admin.failed_email_retries.batch_failed')
      )
      expect(response).to redirect_to(super_admin_app_config_path(config: 'internal'))
    end

    it 'does not create a second active batch' do
      active_batch = create(:failed_email_retry_batch, requested_by: super_admin, status: :processing)
      sign_in(super_admin, scope: :super_admin)

      expect do
        post '/super_admin/failed_email_retry_batches', params: { lookback_hours: 1 }
      end.not_to change(FailedEmailRetryBatch, :count)

      expect(response).to redirect_to(
        super_admin_app_config_path(
          config: 'internal',
          lookback_hours: active_batch.lookback_hours,
          failed_email_retry_batch_id: active_batch.id
        )
      )
    end
  end

  describe 'GET /super_admin/failed_email_retry_batches/:id' do
    let(:batch) do
      create(
        :failed_email_retry_batch,
        requested_by: super_admin,
        candidate_count: 4,
        eligible_count: 3,
        scheduled_count: 2,
        skipped_count: 1,
        error_count: 1
      )
    end

    it 'redirects an unauthenticated super admin' do
      get "/super_admin/failed_email_retry_batches/#{batch.id}"

      expect(response).to have_http_status(:redirect)
    end

    it 'returns the batch status to an authenticated super admin' do
      sign_in(super_admin, scope: :super_admin)
      get "/super_admin/failed_email_retry_batches/#{batch.id}", as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include(
        'id' => batch.id,
        'status' => 'queued',
        'candidate_count' => 4,
        'eligible_count' => 3,
        'scheduled_count' => 2,
        'skipped_count' => 1,
        'error_count' => 1,
        'created_at' => batch.created_at.iso8601,
        'started_at' => nil,
        'active' => true
      )
    end
  end
end
