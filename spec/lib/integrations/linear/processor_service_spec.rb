require 'rails_helper'

describe Integrations::Linear::ProcessorService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:processor) { described_class.new(account: account, conversation: conversation) }
  let(:api_key) { 'valid_api_key' }
  let(:url) { 'https://api.linear.app/graphql' }
  let(:headers) { { 'Content-Type' => 'application/json', 'Authorization' => api_key } }

  let(:schema) { JSON.parse(File.read('spec/fixtures/linear-schema.json')) }
  let(:linear_client) { Graphlient::Client.new(url, schema: Graphlient::Schema.new({ 'data' => schema }, nil), headers: headers) }
  let(:linear_instance) { Linear.new(api_key) }

  before do
    create(:integrations_hook, :linear, account: account)
  end

  describe '#teams' do
    context 'when the API response is success' do
      before do
        linear_instance.instance_variable_set(:@client, linear_client)
        processor.instance_variable_set(:@linear_client, linear_instance)
        stub_request(:post, url)
          .to_return(status: 200, body: { data: { teams: { nodes: [{ id: 'team1', name: 'Team One' }] } } }.to_json)
      end

      it 'returns the list of teams' do
        result = processor.teams
        expect(result).to eq([{ 'id' => 'team1', 'name' => 'Team One' }])
      end
    end
  end
end
