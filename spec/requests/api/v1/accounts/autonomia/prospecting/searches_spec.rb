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
             requested_limit: 2,
             metadata: {
               location_place_id: 'places/curitiba',
               location_latitude: -25.4284,
               location_longitude: -49.2733,
               location_label: 'Curitiba, PR, Brasil'
             }
           }
         },
         headers: auth_headers(admin)

    expect(response).to have_http_status(:created)
    payload = response.parsed_body['payload']
    expect(payload.dig('search', 'status')).to eq('completed')
    expect(payload['leads'].size).to eq(2)
    expect(account.autonomia_prospecting_searches.count).to eq(1)
    expect(account.autonomia_prospecting_leads.count).to eq(2)
    expect(payload.dig('search', 'location_place_id')).to eq('places/curitiba')
    expect(payload.dig('search', 'location_latitude')).to eq(-25.4284)
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

  it 'returns Google location suggestions without exposing the API key' do
    Autonomia::Prospecting::Setting.for_account(account).update!(
      google_places_api_key: 'secret-key'
    )
    stub_request(:post, 'https://places.googleapis.com/v1/places:autocomplete')
      .to_return(
        status: 200,
        body: {
          suggestions: [
            {
              placePrediction: {
                placeId: 'places/divinopolis',
                text: { text: 'Divinopolis, MG, Brasil' }
              }
            }
          ]
        }.to_json
      )

    get "/api/v1/accounts/#{account.id}/autonomia/prospecting/searches/location_suggestions",
        params: { query: 'Divino' },
        headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload']).to contain_exactly(
      { 'text' => 'Divinopolis, MG, Brasil', 'place_id' => 'places/divinopolis' }
    )
  end

  it 'returns Google location details for a selected place' do
    Autonomia::Prospecting::Setting.for_account(account).update!(
      google_places_api_key: 'secret-key'
    )
    stub_request(:get, 'https://places.googleapis.com/v1/places/places/divinopolis')
      .to_return(
        status: 200,
        body: {
          id: 'places/divinopolis',
          formattedAddress: 'Divinopolis, MG, Brasil',
          location: { latitude: -20.1446, longitude: -44.8912 }
        }.to_json
      )

    get "/api/v1/accounts/#{account.id}/autonomia/prospecting/searches/location_details",
        params: { place_id: 'places/divinopolis' },
        headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload']).to include(
      'place_id' => 'places/divinopolis',
      'label' => 'Divinopolis, MG, Brasil',
      'latitude' => -20.1446,
      'longitude' => -44.8912
    )
  end

  it 'deletes a recent search without deleting its leads' do
    search = Autonomia::Prospecting::Search.create!(
      account: account,
      user: admin,
      query: 'restaurante',
      requested_limit: 1
    )
    lead = Autonomia::Prospecting::Lead.create!(
      account: account,
      search: search,
      provider: 'mock',
      name: 'Restaurante Central'
    )

    delete "/api/v1/accounts/#{account.id}/autonomia/prospecting/searches/#{search.id}",
           headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(Autonomia::Prospecting::Search.exists?(search.id)).to be(false)
    expect(Autonomia::Prospecting::Lead.exists?(lead.id)).to be(true)
  end

  def auth_headers(user)
    { 'api_access_token' => user.access_token.token }
  end
end
