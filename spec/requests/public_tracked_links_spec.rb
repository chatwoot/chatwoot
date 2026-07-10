require 'rails_helper'

RSpec.describe 'Public tracked links', type: :request do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, phone_number: '+15551234567', provider: 'whatsapp_cloud', validate_provider_config: false,
                              sync_templates: false)
  end
  let(:inbox) { channel.inbox }

  it 'redirects to the WhatsApp link and increments clicks atomically' do
    tracked_link = Ctwa::TrackedLink.create!(
      account: account,
      inbox: inbox,
      name: 'QR Loja',
      code: 'ABC234',
      prefilled_text: 'Quero atendimento',
      clicks_count: 0
    )

    expect do
      get '/l/abc234'
    end.to change { tracked_link.reload.clicks_count }.by(1)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(tracked_link.wa_link)
  end

  it 'returns not found for an unknown code' do
    get '/l/UNKNOWN'

    expect(response).to have_http_status(:not_found)
  end
end
