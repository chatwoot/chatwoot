require 'rails_helper'

RSpec.describe Voice::HubApnsVoipSender do
  let(:sender) { described_class.new(call_id: 1, relay_token: 'relay-token') }
  let(:tokens) { Array.new(described_class::BATCH_SIZE + 1) { |index| "token-#{index}" } }

  before do
    stub_request(:post, ChatwootHub.voip_push_url).to_return do |request|
      { body: { results: JSON.parse(request.body)['tokens'].index_with { { status: 200 } } }.to_json }
    end
  end

  it 'sends the tokens in batches with the relay token' do
    expect(sender.ring(tokens, { 'aps' => {} }).values.uniq).to eq([:sent])
    expect(a_request(:post, ChatwootHub.voip_push_url).with(headers: { 'Authorization' => 'Bearer relay-token' })).to have_been_made.twice
  end

  it 'stops before the next batch once proceed returns false' do
    outcomes = sender.ring(tokens, { 'aps' => {} }, proceed: -> { false })

    expect(outcomes.keys).to eq(tokens.first(described_class::BATCH_SIZE))
    expect(a_request(:post, ChatwootHub.voip_push_url)).to have_been_made.once
  end

  it 'fails the tokens of a batch the hub refuses' do
    stub_request(:post, ChatwootHub.voip_push_url).to_return(status: 401)

    expect(sender.ring(tokens.first(2), { 'aps' => {} })).to eq('token-0' => :failed, 'token-1' => :failed)
  end
end
