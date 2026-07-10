require 'rails_helper'

RSpec.describe 'CTWA tracked links API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, phone_number: '+15551234567', provider: 'whatsapp_cloud', validate_provider_config: false,
                              sync_templates: false)
  end
  let(:inbox) { channel.inbox }

  it 'requires authentication' do
    get "/api/v1/accounts/#{account.id}/ctwa_tracked_links"

    expect(response).to have_http_status(:unauthorized)
  end

  it 'creates a tracked link and returns the public payload' do
    with_modified_env FRONTEND_URL: 'https://app.example.com' do
      post "/api/v1/accounts/#{account.id}/ctwa_tracked_links",
           params: { name: 'Flyer Julho', inbox_id: inbox.id, prefilled_text: 'Quero atendimento' },
           headers: auth_headers(admin)
    end

    expect(response).to have_http_status(:created)
    payload = response.parsed_body['payload']
    tracked_link = Ctwa::TrackedLink.find(payload['id'])

    expect(payload).to include(
      'name' => 'Flyer Julho',
      'code' => tracked_link.code,
      'prefilled_text' => 'Quero atendimento',
      'clicks_count' => 0,
      'conversations_count' => 0,
      'inbox_id' => inbox.id,
      'wa_link' => tracked_link.wa_link,
      'short_url' => "https://app.example.com/l/#{tracked_link.code}"
    )
  end

  it 'lists tracked links for the current account only' do
    own_link = Ctwa::TrackedLink.create!(account: account, inbox: inbox, name: 'Meu link', code: 'ABC234')
    other_account = create(:account)
    other_channel = create(:channel_whatsapp, account: other_account, phone_number: '+15557654321', provider: 'whatsapp_cloud',
                                              validate_provider_config: false, sync_templates: false)
    Ctwa::TrackedLink.create!(account: other_account, inbox: other_channel.inbox, name: 'Outro link', code: 'XYZ789')

    with_modified_env FRONTEND_URL: 'https://app.example.com' do
      get "/api/v1/accounts/#{account.id}/ctwa_tracked_links", headers: auth_headers(admin)
    end

    expect(response).to have_http_status(:ok)
    payload = response.parsed_body['payload']
    expect(payload.pluck('id')).to eq([own_link.id])
    expect(payload.first['short_url']).to eq('https://app.example.com/l/ABC234')
  end

  it 'rejects a non-WhatsApp inbox with 422' do
    api_inbox = create(:inbox, account: account)

    post "/api/v1/accounts/#{account.id}/ctwa_tracked_links",
         params: { name: 'Link inválido', inbox_id: api_inbox.id },
         headers: auth_headers(admin)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(Ctwa::TrackedLink.count).to eq(0)
  end

  it 'destroys a tracked link' do
    tracked_link = Ctwa::TrackedLink.create!(account: account, inbox: inbox, name: 'QR Loja', code: 'ABC234')

    expect do
      delete "/api/v1/accounts/#{account.id}/ctwa_tracked_links/#{tracked_link.id}", headers: auth_headers(admin)
    end.to change(Ctwa::TrackedLink, :count).by(-1)

    expect(response).to have_http_status(:no_content)
  end
end
