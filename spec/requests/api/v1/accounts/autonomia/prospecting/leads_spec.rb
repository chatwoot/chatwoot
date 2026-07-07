require 'rails_helper'

RSpec.describe 'Autonomia prospecting leads API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:lead) do
    Autonomia::Prospecting::Lead.create!(
      account: account,
      provider: 'mock',
      provider_place_id: 'mock-place-1',
      name: 'Alpha Restaurante',
      phone: '+55 11 99999-8888',
      city: 'Sao Paulo',
      state: 'SP',
      country: 'BR'
    )
  end

  before do
    Autonomia::Prospecting::Config.enable_for!(account)
    allow(Crm::Config).to receive(:enabled?).and_return(true)
  end

  it 'converts a prospecting lead into a Chatwoot contact' do
    post "/api/v1/accounts/#{account.id}/autonomia/prospecting/leads/#{lead.id}/contact",
         headers: auth_headers(admin)

    expect(response).to have_http_status(:created)
    payload = response.parsed_body['payload']
    expect(payload.dig('lead', 'contact_id')).to be_present
    expect(payload.dig('lead', 'contact_status')).to eq('created')
    expect(payload.dig('contact', 'phone_number')).to eq('+5511999998888')
    expect(lead.reload.contact_id).to eq(payload.dig('contact', 'id'))
  end

  it 'does not create a duplicate contact when called twice' do
    post "/api/v1/accounts/#{account.id}/autonomia/prospecting/leads/#{lead.id}/contact",
         headers: auth_headers(admin)
    post "/api/v1/accounts/#{account.id}/autonomia/prospecting/leads/#{lead.id}/contact",
         headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(account.contacts.count).to eq(1)
  end

  it 'creates a CRM card from a prospecting lead' do
    pipeline, stage = create_crm_pipeline(account: account, user: admin)

    post "/api/v1/accounts/#{account.id}/autonomia/prospecting/leads/#{lead.id}/crm_card",
         params: { crm_card: { pipeline_id: pipeline.id, stage_id: stage.id } },
         headers: auth_headers(admin)

    expect(response).to have_http_status(:created)
    payload = response.parsed_body['payload']
    expect(payload.dig('lead', 'crm_card_id')).to be_present
    expect(payload.dig('lead', 'crm_status')).to eq('created')
    expect(payload.dig('crm_card', 'pipeline_id')).to eq(pipeline.id)
    expect(payload.dig('crm_card', 'stage_id')).to eq(stage.id)
    expect(lead.reload.crm_card_id).to eq(payload.dig('crm_card', 'id'))
  end

  it 'does not create a duplicate CRM card when called twice' do
    pipeline, stage = create_crm_pipeline(account: account, user: admin)

    2.times do
      post "/api/v1/accounts/#{account.id}/autonomia/prospecting/leads/#{lead.id}/crm_card",
           params: { crm_card: { pipeline_id: pipeline.id, stage_id: stage.id } },
           headers: auth_headers(admin)
    end

    expect(response).to have_http_status(:ok)
    expect(account.crm_cards.count).to eq(1)
  end

  it 'updates lead quality status and discard reason' do
    patch "/api/v1/accounts/#{account.id}/autonomia/prospecting/leads/#{lead.id}",
          params: { lead: { status: 'discarded', discard_reason: 'Fora do perfil' } },
          headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    payload = response.parsed_body['payload']
    expect(payload['status']).to eq('discarded')
    expect(payload['discard_reason']).to eq('Fora do perfil')
    expect(payload['source_label']).to eq('Mock')
    expect(lead.reload).to be_discarded
  end

  def auth_headers(user)
    { 'api_access_token' => user.access_token.token }
  end
end
