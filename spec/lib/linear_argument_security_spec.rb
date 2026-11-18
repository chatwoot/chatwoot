require 'rails_helper'

RSpec.describe Linear do
  let(:client) { described_class.new('test-token') }
  let(:url) { 'https://api.linear.app/graphql' }
  let(:malicious_id) { "id\"\\\nquery" }

  it 'keeps a submitted team id inside both GraphQL string arguments' do
    request = stub_request(:post, url).with do |http_request|
      query = JSON.parse(http_request.body)['query']
      arguments = query.scan(/eq: ("(?:\\.|[^"\\])*")/).flatten
      expect(arguments.map { |argument| JSON.parse(argument) }).to eq([malicious_id, malicious_id])
      true
    end.to_return(status: 200, body: { data: { users: { nodes: [] } } }.to_json, headers: { 'Content-Type' => 'application/json' })

    client.team_entities(malicious_id)

    expect(request).to have_been_requested.once
  end

  it 'keeps a submitted attachment id inside the delete mutation string argument' do
    request = stub_request(:post, url).with do |http_request|
      query = JSON.parse(http_request.body)['query']
      argument = query.match(/attachmentDelete\(id: ("(?:\\.|[^"\\])*")\)/)
      expect(argument).not_to be_nil
      expect(JSON.parse(argument[1])).to eq(malicious_id)
      true
    end.to_return(status: 200, body: { data: { attachmentDelete: { success: true } } }.to_json,
                  headers: { 'Content-Type' => 'application/json' })

    client.unlink_issue(malicious_id)

    expect(request).to have_been_requested.once
  end
end
