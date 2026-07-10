require 'rails_helper'

RSpec.describe 'Public tracked links', type: :request do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, phone_number: '+15551234567', provider: 'whatsapp_cloud', validate_provider_config: false,
                              sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let!(:tracked_link) do
    Ctwa::TrackedLink.create!(
      account: account,
      inbox: inbox,
      name: 'QR Loja',
      code: 'ABC234',
      prefilled_text: 'Quero atendimento',
      clicks_count: 0
    )
  end

  it 'redirects to the WhatsApp link and increments clicks atomically' do
    expect do
      get '/l/abc234'
    end.to change { tracked_link.reload.clicks_count }.by(1)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(tracked_link.wa_link)
  end

  it 'keeps the legacy redirect and does not create a click record without tracking params' do
    expect do
      get '/l/abc234'
    end.not_to change(Ctwa::TrackedLinkClick, :count)

    expect(response).to redirect_to(tracked_link.wa_link)
  end

  it 'captures whitelisted tracking params and redirects with the click token' do
    user_agent = "Mozilla/#{'A' * 300}"

    expect do
      get '/l/abc234',
          params: { gclid: 'gclid-123', utm_campaign: 'july', utm_source: 'google', ignored: 'drop-me' },
          headers: { 'HTTP_USER_AGENT' => user_agent }
    end.to change(Ctwa::TrackedLinkClick, :count).by(1)

    click = Ctwa::TrackedLinkClick.last
    expect(response).to have_http_status(:found)
    expect(CGI.parse(URI.parse(response.location).query)['text'].first).to eq("Quero atendimento ##{click.token}")
    expect(click).to have_attributes(account_id: account.id, tracked_link_id: tracked_link.id)
    expect(click.params).to eq('gclid' => 'gclid-123', 'utm_campaign' => 'july', 'utm_source' => 'google')
    expect(click.user_agent.length).to eq(255)
  end

  it 'captures a click when any whitelisted UTM param is present' do
    get '/l/abc234', params: { utm_medium: 'cpc' }

    click = Ctwa::TrackedLinkClick.last
    expect(CGI.parse(URI.parse(response.location).query)['text'].first).to eq("Quero atendimento ##{click.token}")
    expect(click.params).to eq('utm_medium' => 'cpc')
  end

  it 'falls back to the legacy redirect when click capture fails' do
    allow(Ctwa::TrackedLinkClick).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    expect do
      get '/l/abc234', params: { gclid: 'gclid-123' }
    end.not_to change(Ctwa::TrackedLinkClick, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(tracked_link.wa_link)
  end

  it 'returns not found for an unknown code' do
    get '/l/UNKNOWN'

    expect(response).to have_http_status(:not_found)
  end
end
