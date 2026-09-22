require 'rails_helper'

RSpec.describe 'Copilot V2 API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user, engine: :v2, assistant: nil) }
  let(:message) { create(:captain_copilot_message, copilot_thread: thread, message: { content: 'Find requests' }) }
  let(:run) { thread.copilot_runs.create!(triggering_message: message, status: 'incomplete') }
  let(:base_url) { "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{thread.id}" }
  let(:headers) { user.create_new_auth_token }

  before { account.enable_features!('copilot_v2') }

  it 'reads stored results while disabled and paginates display without changing coverage' do
    run.update!(result_summary: { 'answer' => 'Saved answer', 'results' => [{ 'rows' => [{ 'id' => 7 }, { 'id' => 8 }],
                                                                              'selected_ids' => [7, 8], 'resolved_ids' => [7, 8],
                                                                              'selected_count' => 2, 'processing_complete' => true }] })
    account.disable_features!('copilot_v2')
    get "#{base_url}/copilot_runs/#{run.id}", params: { page: 2, per_page: 1 }, headers: headers

    expect(response).to have_http_status(:ok)
    result = response.parsed_body
    expect(result['answer']).to eq('Saved answer')
    expect(result['execution_availability']).to eq('available' => false, 'reason' => 'feature_disabled')
    expect(result['results'].first).to include('rows' => [{ 'id' => 8 }], 'selected_count' => 2, 'processing_complete' => true)
    expect(result['results'].first.dig('pagination', 'rows', 'total')).to eq(2)
    expect(run.reload.result_summary['results'].first['rows'].size).to eq(2)
  end

  it 'hides runs from another account administrator on every route' do
    other = create(:user, account: account, role: :administrator)
    get "#{base_url}/copilot_runs/#{run.id}", headers: other.create_new_auth_token
    expect(response).to have_http_status(:not_found)
    post "#{base_url}/copilot_runs/#{run.id}/resume", headers: other.create_new_auth_token
    expect(response).to have_http_status(:not_found)
    post "#{base_url}/copilot_runs/#{run.id}/cancel", headers: other.create_new_auth_token
    expect(response).to have_http_status(:not_found)
  end

  it 'cannot read a run through another owned thread or account' do
    another = create(:captain_copilot_thread, account: account, user: user, engine: :v2, assistant: nil)
    get "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{another.id}/copilot_runs/#{run.id}", headers: headers
    expect(response).to have_http_status(:not_found)
    other_account = create(:account)
    get "/api/v1/accounts/#{other_account.id}/captain/copilot_threads/#{thread.id}/copilot_runs/#{run.id}", headers: headers
    expect(response).not_to have_http_status(:ok)
  end

  it 'resumes incomplete runs and prevents duplicate resume' do
    post "#{base_url}/copilot_runs/#{run.id}/resume", headers: headers
    expect(response).to have_http_status(:ok)
    expect(run.reload.status).to eq('queued')
    expect(Copilot::V2::RunJob).to have_been_enqueued.with(run.id).once
    post "#{base_url}/copilot_runs/#{run.id}/resume", headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Copilot::V2::RunJob).to have_been_enqueued.with(run.id).once
  end

  it 'rejects disabled execution but allows cancellation' do
    run
    account.disable_features!('copilot_v2')
    post "#{base_url}/copilot_runs/#{run.id}/resume", headers: headers
    expect(response).to have_http_status(:forbidden)
    expect(run.reload.status).to eq('incomplete')
    post "#{base_url}/copilot_runs/#{run.id}/cancel", headers: headers
    expect(response).to have_http_status(:ok)
    expect(run.reload.status).to eq('cancelled')
  end

  it 'rolls back a conflicting message and does not enqueue work' do
    run.update!(status: 'queued')
    expect do
      post "#{base_url}/copilot_messages", params: { message: 'Another task' }, headers: headers, as: :json
    end.not_to change(CopilotMessage, :count)
    expect(response).to have_http_status(:conflict)
    expect(Copilot::V2::RunJob).not_to have_been_enqueued
  end

  it 'rolls back disabled messages' do
    thread
    account.disable_features!('copilot_v2')
    expect do
      post "#{base_url}/copilot_messages", params: { message: 'Another task' }, headers: headers, as: :json
    end.not_to change(CopilotMessage, :count)
    expect(response).to have_http_status(:forbidden)
  end

  it 'answers pending clarification in the same run with a dedicated association' do
    run.update!(status: 'needs_clarification', checkpoint: { 'transcript' => [] }, result_summary: { 'question' => 'Which period?' })
    expect do
      post "#{base_url}/copilot_messages", params: { message: 'Last week' }, headers: headers, as: :json
    end.not_to change(CopilotRun, :count)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('message' => { 'content' => 'Last week' }, 'copilot_run_id' => run.id)
    expect(run.reload.status).to eq('queued')
    expect(run.task_spec['clarifications']).to eq(['Last week'])
    expect(Copilot::V2::RunJob).to have_been_enqueued.with(run.id).once
  end

  it 'rejects malformed v2 messages and page parameters' do
    expect do
      post "#{base_url}/copilot_messages", params: { message: { content: 'Nested' } }, headers: headers, as: :json
    end.not_to change(CopilotMessage, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    get "#{base_url}/copilot_runs/#{run.id}", params: { page: '1abc' }, headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'creates the initial run synchronously and reports the saved engine' do
    post "/api/v1/accounts/#{account.id}/captain/copilot_threads", params: { message: 'Find requests' }, headers: headers, as: :json
    expect(response).to have_http_status(:ok)
    saved = CopilotThread.last
    expect(saved.copilot_runs.count).to eq(1)
    expect(saved.copilot_messages.first.copilot_run).to eq(saved.copilot_runs.first)
    expect(Copilot::V2::RunJob).to have_been_enqueued.with(saved.copilot_runs.first.id).once
    expect(Copilot::V2::ResponseJob).not_to have_been_enqueued
    expect(response.parsed_body).to include('engine' => 'v2')
  end

  it 'rejects new execution without credits without leaving a thread or message' do
    account.update!(limits: { captain_responses: 0 })
    expect do
      post "/api/v1/accounts/#{account.id}/captain/copilot_threads", params: { message: 'Find requests' }, headers: headers, as: :json
    end.not_to change(CopilotThread, :count)
    expect(response).to have_http_status(:forbidden)
    expect(CopilotMessage.count).to eq(0)
    expect(Copilot::V2::RunJob).not_to have_been_enqueued
  end

  it 'resumes a charged run after credits are exhausted while blocking uncharged runs' do
    run.update!(charged_at: Time.current)
    account.update!(limits: { captain_responses: 0 })
    post "#{base_url}/copilot_runs/#{run.id}/resume", headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['execution_availability']).to eq('available' => true, 'reason' => nil)
    expect(thread.reload.execution_availability).to eq(available: false, reason: 'response_credits_unavailable')
    run.reload.update!(status: 'incomplete', charged_at: nil)
    post "#{base_url}/copilot_runs/#{run.id}/resume", headers: headers
    expect(response).to have_http_status(:forbidden)
    expect(run.reload.status).to eq('incomplete')
  end

  it 'reports revoked membership as unavailable in saved progress metadata' do
    run
    account.account_users.find_by!(user: user).destroy!
    expect(run.push_event_data[:execution_availability]).to eq(available: false, reason: 'access_unavailable')
  end

  it 'returns empty displayed lists for extremely large pages' do
    run.update!(result_summary: { 'results' => [{ 'rows' => [{ 'id' => 1 }], 'processing_complete' => true }] })
    get "#{base_url}/copilot_runs/#{run.id}", params: { page: '9' * 80 }, headers: headers
    expect(response).to have_http_status(:ok)
    projection = response.parsed_body['results'].first
    expect(projection).to include('rows' => [], 'processing_complete' => true)
    expect(projection.dig('pagination', 'rows', 'total')).to eq(1)
  end
end
