require 'rails_helper'

RSpec.describe 'Autonomia prospecting searches API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }

  before do
    Autonomia::Prospecting::Config.enable_for!(account)
  end

  it 'runs a mock search for account administrators' do
    post "/api/v1/accounts/#{account.id}/autonomia/prospecting/searches",
         params: {
           search: {
             query: 'clinica odontologica',
             location: 'Curitiba, PR',
             requested_limit: 2
           }
         },
         headers: auth_headers(admin)

    expect(response).to have_http_status(:created)
    payload = response.parsed_body['payload']
    expect(payload.dig('search', 'status')).to eq('completed')
    expect(payload['leads'].size).to eq(2)
    expect(account.autonomia_prospecting_searches.count).to eq(1)
    expect(account.autonomia_prospecting_leads.count).to eq(2)
  end

  it 'blocks accounts without the prospecting flag' do
    Autonomia::Prospecting::Config.disable_for!(account)

    get "/api/v1/accounts/#{account.id}/autonomia/prospecting/searches", headers: auth_headers(admin)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body['error']).to eq('autonomia.prospecting.disabled')
  end

  it 'blocks non-admin users' do
    agent = create(:user, account: account, role: :agent)

    post "/api/v1/accounts/#{account.id}/autonomia/prospecting/searches",
         params: { search: { query: 'restaurante', requested_limit: 1 } },
         headers: auth_headers(agent)

    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects blank queries' do
    post "/api/v1/accounts/#{account.id}/autonomia/prospecting/searches",
         params: { search: { query: '', requested_limit: 1 } },
         headers: auth_headers(admin)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']).to include("Query can't be blank")
  end

  it 'updates CRM target for a saved search' do
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    search = Autonomia::Prospecting::Search.create!(
      account: account,
      user: admin,
      query: 'restaurante',
      requested_limit: 1
    )

    patch "/api/v1/accounts/#{account.id}/autonomia/prospecting/searches/#{search.id}",
          params: { search: { crm_pipeline_id: pipeline.id, crm_stage_id: stage.id } },
          headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    payload = response.parsed_body['payload']
    expect(payload['crm_pipeline_id']).to eq(pipeline.id)
    expect(payload['crm_stage_id']).to eq(stage.id)
    expect(search.reload.metadata['crm_pipeline_id']).to eq(pipeline.id.to_s)
  end

  def auth_headers(user)
    { 'api_access_token' => user.access_token.token }
  end
end
