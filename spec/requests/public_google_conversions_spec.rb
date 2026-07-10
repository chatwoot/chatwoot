require 'rails_helper'

RSpec.describe 'Public Google conversions feed', type: :request do
  let(:account) { create(:account, custom_attributes: { 'google_feed_token' => 'strong-feed-token' }) }

  it 'returns not found for an invalid token' do
    get '/google_conversions/invalid.csv'

    expect(response).to have_http_status(:not_found)
  end

  it 'renders the official scheduled click import columns with ready events from the last 90 days' do
    ready = create(:crm_google_conversion_event, account: account, gclid: 'GCLID-READY', conversion_name: 'Venda WhatsApp',
                                                 conversion_time: Time.zone.parse('2026-07-09 12:34:56 UTC'), value_cents: 12_345,
                                                 currency: 'BRL')
    create(:crm_google_conversion_event, account: account, status: 'skipped', gclid: nil, skip_reason: 'missing_gclid')
    create(:crm_google_conversion_event, account: account, gclid: 'GCLID-OLD', conversion_time: 91.days.ago)

    travel_to(Time.zone.parse('2026-07-10 12:00:00 UTC')) do
      get '/google_conversions/strong-feed-token.csv'
    end

    rows = CSV.parse(response.body)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/csv')
    expect(response.headers['Cache-Control']).to include('no-store')
    expect(rows).to eq([
                         ['Parameters:TimeZone=+00:00'],
                         ['Google Click ID', 'Conversion Name', 'Conversion Time', 'Conversion Value', 'Conversion Currency'],
                         [ready.gclid, ready.conversion_name, '2026-07-09 12:34:56+0000', '123.45', 'BRL']
                       ])
  end

  it 'leaves optional value and currency columns empty for non-revenue conversions' do
    create(:crm_google_conversion_event, account: account, conversion_name: 'Qualificação', value_cents: nil, currency: nil)

    get '/google_conversions/strong-feed-token.csv'

    expect(CSV.parse(response.body).last.last(2)).to eq([nil, nil])
  end

  it 'leaves zero value and currency blank because Google accepts only positive conversion values' do
    create(:crm_google_conversion_event, account: account, value_cents: 0, currency: 'BRL')

    get '/google_conversions/strong-feed-token.csv'

    expect(CSV.parse(response.body).last.last(2)).to eq([nil, nil])
  end
end
