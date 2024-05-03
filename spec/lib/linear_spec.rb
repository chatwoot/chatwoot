require 'rails_helper'

describe Linear do
  let(:api_key) { 'valid_api_key' }
  let(:url) { 'https://api.linear.app/graphql' }
  let(:linear_client) { described_class.new(api_key) }
  let(:headers) { { 'Content-Type' => 'application/json', 'Authorization' => api_key } }

  let(:schema) { JSON.parse(File.read('spec/fixtures/linear-schema.json')) }
  let(:client) { Graphlient::Client.new(url, schema: Graphlient::Schema.new({ 'data' => schema }, nil), headers: headers) }

  it 'raises an exception if the API key is absent' do
    expect { described_class.new(nil) }.to raise_error(ArgumentError, 'Missing Credentials')
  end

  context 'when querying teams' do
    let(:teams_query) do
      <<~GRAPHQL
        query {
          teams {
            nodes {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    context 'when the API response is success' do
      before do
        linear_client.instance_variable_set(:@client, client)
        stub_request(:post, url)
          .to_return(status: 200, body: { data: { teams: { nodes: [{ id: 'team1', name: 'Team One' }] } } }.to_json)
      end

      it 'returns team data' do
        response = linear_client.teams
        expect(response).to eq({ 'teams' => { 'nodes' => [{ 'id' => 'team1', 'name' => 'Team One' }] } })
      end
    end
  end
end
