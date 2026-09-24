require 'rails_helper'

RSpec.describe 'Monitors API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }
  let(:base) { "/api/v1/accounts/#{account.id}/monitors" }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:conversation) { create(:conversation, account: account, created_at: 2.days.ago) }
  let(:message) { create(:message, account: account, conversation: conversation, content: 'Please refund my order') }
  let(:query) { { since: 7.days.ago.to_i, until: Time.current.to_i, interval: 'day', timezone: 'UTC' } }
  let(:preview_key) { ConversationMonitors::PreviewJob.cache_key(account.id, admin.id, 'sample') }

  before do
    account.enable_features!('reports', 'conversation_monitors')
    create(:installation_config, name: 'CAPTAIN_OPENROUTER_API_KEY', value: 'test-key')
  end

  after { Redis::Alfred.delete(preview_key) }

  it 'creates a durable historical scan with immutable evaluation settings' do
    expect do
      post base, headers: headers, params: { name: 'Refunds', condition: 'Mentions refunds' }, as: :json
    end.to have_enqueued_job(ConversationMonitors::ScanJob)

    expect(response).to have_http_status(:created)
    created = account.conversation_monitors.sole
    expect(created.initial_scan).to be_present
    expect(created.threshold).to eq(0.6)
    expect(created.history_since).to be_within(5.seconds).of(7.days.ago)
  end

  it 'rejects overlong creation fields at the monitor request boundary' do
    [{ name: 'x' * 101, condition: 'Refunds' }, { name: 'Refunds', condition: 'x' * 2001 }].each do |attributes|
      post base, headers: headers, params: attributes, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq('error' => 'invalid_parameters')
    end
    expect(account.conversation_monitors).not_to exist
  end

  it 'isolates definitions and results between accounts' do
    other = create(:conversation_monitor)

    get "#{base}/#{other.id}", headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it 'returns the created monitor when queueing fails and leaves its scan recoverable' do
    allow(ConversationMonitors::ScanJob).to receive(:perform_later).and_raise(Redis::CannotConnectError)

    post base, headers: headers, params: { name: 'Refunds', condition: 'Mentions refunds' }, as: :json

    expect(response).to have_http_status(:created)
    created = account.conversation_monitors.sole
    expect(created.initial_scan.enumerated_at).to be_nil
    allow(ConversationMonitors::ScanJob).to receive(:perform_later).and_call_original
    expect { ConversationMonitors::DispatchJob.perform_now }.to have_enqueued_job(ConversationMonitors::ScanJob).with(created.initial_scan.id)
  end

  it 'blocks feature-disabled accounts on the direct API' do
    account.disable_features!('conversation_monitors')
    get base, headers: headers

    expect(response).to have_http_status(:forbidden)
    expect(create(:account).feature_enabled?('conversation_monitors')).to be(false)
  end

  it 'returns shared account usage on the list and every monitor without hiding historical reports' do
    other_monitor = create(:conversation_monitor, account: account)
    now = Time.current.utc
    ConversationMonitors::DailyUsage.create!(account: account, usage_date: now.to_date, calls_count: 100_000, limit_reached_at: now)

    get base, headers: headers
    usage = response.parsed_body.dig('meta', 'usage')
    expect(usage).to include('limit' => 100_000, 'used' => 100_000, 'remaining' => 0, 'limit_reached' => true,
                             'limit_reached_at' => now.to_i, 'resets_at' => now.beginning_of_month.next_month.to_i)
    [monitor, other_monitor].each do |record|
      get "#{base}/#{record.id}/timeseries", headers: headers, params: query
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['usage']).to eq(usage)
      get "#{base}/#{record.id}", headers: headers
      expect(response.parsed_body['usage']).to eq(usage)
    end
  end

  it 'applies the same allowance to preview and does not send requests after exhaustion' do
    message
    ConversationMonitors::DailyUsage.create!(account: account, usage_date: Time.current.utc.to_date, calls_count: 100_000,
                                             limit_reached_at: Time.current)
    ConversationMonitors::PreviewJob.write(preview_key, { status: 'pending', condition: 'refund' })
    ConversationMonitors::PreviewJob.perform_now(account.id, admin.id, 'sample')

    expect(WebMock).not_to have_requested(:post, ConversationMonitors::Configuration.endpoint)
    expect(ConversationMonitors::PreviewJob.read(preview_key)).to include(status: 'error', error: 'monthly_limit')
  end

  it 'allows aggregate report viewers but reserves drilldown and management for administrators' do
    role = create(:custom_role, account: account, permissions: ['report_manage'])
    user = create(:user, account: account, role: :agent)
    account.account_users.find_by!(user: user).update!(custom_role: role)
    viewer_headers = user.create_new_auth_token

    get "#{base}/#{monitor.id}/timeseries", headers: viewer_headers, params: query
    expect(response).to have_http_status(:ok)
    get "#{base}/#{monitor.id}/conversations", headers: viewer_headers, params: query
    expect(response).to have_http_status(:unauthorized)
    post base, headers: viewer_headers, params: { name: 'Not allowed', condition: 'refund' }, as: :json
    expect(response).to have_http_status(:unauthorized)
    post "#{base}/preview", headers: viewer_headers, params: { condition: 'refund' }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'returns a distinct preview cooldown with the remaining retry time and does not queue another preview' do
    post "#{base}/preview", headers: headers, params: { condition: 'Refunds' }, as: :json
    expect(response.parsed_body['retry_after']).to eq(30)
    key = "conversation_monitors:preview_limit:#{account.id}:#{admin.id}"
    Redis::Alfred.expire(key, 20)

    expect do
      post "#{base}/preview", headers: headers, params: { condition: 'WhatsApp BSUID' }, as: :json
    end.not_to have_enqueued_job(ConversationMonitors::PreviewJob)

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body['error']).to eq('preview_rate_limit')
    expect(response.parsed_body['retry_after']).to be_between(1, 20)
    expect(response.headers['Retry-After']).to eq(response.parsed_body['retry_after'].to_s)

    Redis::Alfred.delete(key)
    expect do
      post "#{base}/preview", headers: headers, params: { condition: 'WhatsApp BSUID' }, as: :json
    end.to have_enqueued_job(ConversationMonitors::PreviewJob)
  end

  it 'keeps chart counts and drilldown membership identical and rejects stale revisions' do
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    get "#{base}/#{monitor.id}/timeseries", headers: headers, params: query
    chart = response.parsed_body
    bucket = chart['buckets'].find { |entry| entry['count'].positive? }
    params = query.merge(bucket_start: bucket['start'], data_revision: chart['data_revision'])

    get "#{base}/#{monitor.id}/conversations", headers: headers, params: params
    expect(response.parsed_body.dig('meta', 'total_count')).to eq(bucket['count'])
    expect(response.parsed_body['payload'].map { |record| record.dig('conversation', 'id') }).to eq([conversation.id])

    monitor.update!(data_revision: monitor.data_revision + 1)
    get "#{base}/#{monitor.id}/conversations", headers: headers, params: params
    expect(response).to have_http_status(:conflict)
  end

  it 'does not expose a deleted conversation from a completed preview' do
    message
    stub_request(:post, ConversationMonitors::Configuration.endpoint).to_return(
      status: 200, body: { model: 'typesafe/jev-1.13-20260917', answers: { '0' => { type: 'noul', noul: 0.6 } }, usage: { input_tokens: 10 } }.to_json
    )
    ConversationMonitors::PreviewJob.write(preview_key, { status: 'pending', condition: 'refund' })
    ConversationMonitors::PreviewJob.perform_now(account.id, admin.id, 'sample')
    expect(ConversationMonitors::PreviewJob.read(preview_key)[:conversation_ids]).to eq([conversation.id])
    conversation.destroy!

    get "#{base}/preview/sample", headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload']).to be_empty
  end

  it 'does not retain source text in preview storage or return redacted text later' do
    message
    stub_request(:post, ConversationMonitors::Configuration.endpoint).to_return(
      status: 200, body: { model: 'typesafe/jev-1.13-20260917', answers: { '0' => { type: 'noul', noul: 0.99 } },
                           usage: { input_tokens: 10 } }.to_json
    )
    ConversationMonitors::PreviewJob.write(preview_key, { status: 'pending', condition: 'refund' })
    ConversationMonitors::PreviewJob.perform_now(account.id, admin.id, 'sample')
    expect(Redis::Alfred.get(preview_key)).not_to include(message.content)
    message.update!(content: 'Deleted', content_attributes: { deleted: true })

    get "#{base}/preview/sample", headers: headers

    expect(response.body).not_to include('Please refund my order')
  end

  it 'does not evaluate completed previews again on duplicate delivery' do
    message
    ConversationMonitors::PreviewJob.write(preview_key, { status: 'complete', sampled: 1, excluded: 0, conversation_ids: [conversation.id] })

    ConversationMonitors::PreviewJob.perform_now(account.id, admin.id, 'sample')

    expect(WebMock).not_to have_requested(:post, ConversationMonitors::Configuration.endpoint)
    expect(ConversationMonitors::PreviewJob.read(preview_key)[:status]).to eq('complete')
  end

  it 'updates the description and deletes the monitor without removing source conversations' do
    patch "#{base}/#{monitor.id}", headers: headers, params: { condition: 'a new condition', collection_version: 0 }, as: :json
    expect(response).to have_http_status(:ok)
    expect(monitor.reload.condition).to eq('a new condition')
    expect { delete "#{base}/#{monitor.id}", headers: headers }.to have_enqueued_job(ConversationMonitors::BroadcastJob).with(
      monitor.id, { account_id: account.id, monitor_id: monitor.id, data_revision: 2, deleted: true }
    )
    expect(response).to have_http_status(:no_content)
    get "#{base}/#{monitor.id}", headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it 'rejects invalid descriptions and stale edits without replacing the current rule' do
    ['', 'a' * 2001, ['refund'], { text: 'refund' }].each do |condition|
      patch "#{base}/#{monitor.id}", headers: headers, params: { condition: condition, collection_version: 0 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('invalid_parameters')
    end

    patch "#{base}/#{monitor.id}", headers: headers, params: { condition: 'new', collection_version: 1 }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('monitor_changed')
    expect(monitor.reload.condition).to eq('All conversations mentioning refunds')
  end

  it 'pauses collection while preserving historical counts and administrator drilldowns' do
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    patch "#{base}/#{monitor.id}", headers: headers, params: { paused: true }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('processing', 'state')).to eq('paused')
    expect(response.parsed_body['paused_at']).to be_within(1).of(Time.current.to_i)
    monitor.reload
    expect(monitor).not_to be_collecting
    expect(account.conversation_monitors.active).not_to include(monitor)

    get "#{base}/#{monitor.id}/timeseries", headers: headers, params: query
    chart = response.parsed_body
    expect(chart['total_count']).to eq(1)
    bucket = chart['buckets'].find { |entry| entry['count'].positive? }
    get "#{base}/#{monitor.id}/conversations", headers: headers,
                                               params: query.merge(bucket_start: bucket['start'], data_revision: chart['data_revision'])
    expect(response.parsed_body.dig('meta', 'total_count')).to eq(1)
  end

  it 'keeps the original pause time on repeated pauses and prevents manual retries' do
    monitor.update!(paused_at: 1.hour.ago)
    paused_at = monitor.paused_at
    patch "#{base}/#{monitor.id}", headers: headers, params: { paused: true }, as: :json
    expect(monitor.reload.paused_at).to eq(paused_at)
    post "#{base}/#{monitor.id}/retry_evaluations", headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to eq('monitor_paused')
  end

  it 'keeps a paused monitor card count anchored to its pause time' do
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    monitor.update!(paused_at: Time.current)
    travel_to(30.days.from_now) do
      get "#{base}/#{monitor.id}", headers: headers

      expect(response.parsed_body['recent_count']).to eq(1)
      expect(response.parsed_body.dig('processing', 'state')).to eq('paused')
    end
  end

  it 'requires administrator access and a boolean to pause' do
    user = create(:user, account: account, role: :agent)
    role = create(:custom_role, account: account, permissions: ['report_manage'])
    account.account_users.find_by!(user: user).update!(custom_role: role)
    patch "#{base}/#{monitor.id}", headers: user.create_new_auth_token, params: { paused: true }, as: :json
    expect(response).to have_http_status(:unauthorized)
    patch "#{base}/#{monitor.id}", headers: headers, params: { paused: 'true' }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(monitor.reload.paused_at).to be_nil
  end

  it 'resumes the same monitor with an explicit mode and returns its new collection version' do
    monitor.update!(paused_at: 2.hours.ago)
    expect do
      post "#{base}/#{monitor.id}/resume", headers: headers, params: { mode: 'catch_up', collection_version: 0 }, as: :json
    end.to have_enqueued_job(ConversationMonitors::ScanJob)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['paused_at']).to be_nil
    expect(response.parsed_body['collection_version']).to eq(1)
    expect(response.parsed_body.dig('processing', 'state')).to eq('catching_up')
    expect(monitor.scans.where.not(kind: 'initial').sole.kind).to eq('catch_up')
  end

  it 'requires administrator access and a documented resume mode' do
    monitor.update!(paused_at: 2.hours.ago)
    user = create(:user, account: account, role: :agent)
    role = create(:custom_role, account: account, permissions: ['report_manage'])
    account.account_users.find_by!(user: user).update!(custom_role: role)
    post "#{base}/#{monitor.id}/resume", headers: user.create_new_auth_token, params: { mode: 'from_now', collection_version: 0 }, as: :json
    expect(response).to have_http_status(:unauthorized)
    post "#{base}/#{monitor.id}/resume", headers: headers, params: { mode: 'invalid', collection_version: 0 }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(monitor.reload.paused_at).to be_present
  end
end
