require 'rails_helper'

RSpec.describe Notion::ApiClient do
  let(:access_token) { 'notion_access_token' }
  let(:client) { described_class.new(access_token) }
  let(:headers) do
    {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json',
      'Notion-Version' => '2026-03-11'
    }
  end

  before do
    allow(GlobalConfigService).to receive(:load).with('NOTION_VERSION', '2026-03-11').and_return('2026-03-11')
  end

  it 'sends the configured Notion version header' do
    stub_request(:get, 'https://api.notion.com/v1/users')
      .with(headers: headers)
      .to_return(status: 200, body: { results: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

    client.get('/users')

    expect(WebMock).to have_requested(:get, 'https://api.notion.com/v1/users')
      .with(headers: headers)
  end

  it 'normalizes failed responses with the response code' do
    stub_request(:get, 'https://api.notion.com/v1/pages/missing-page')
      .to_return(status: 404, body: { object: 'error', message: 'Not found' }.to_json, headers: { 'Content-Type' => 'application/json' })

    response = client.get('pages/missing-page')

    expect(response).to eq({ error: { 'object' => 'error', 'message' => 'Not found' }, error_code: 404 })
  end

  it 'raises an error when the access token is missing' do
    expect { described_class.new(nil) }.to raise_error(ArgumentError, 'Missing Credentials')
  end
end
