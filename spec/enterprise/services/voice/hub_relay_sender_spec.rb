require 'rails_helper'

RSpec.describe Voice::HubRelaySender do
  let(:sender) { described_class.new(platform: 'apple', call_id: 1, expiry_seconds: 45) }
  let(:relay_url) { "#{ChatwootHub.base_url}/voice_relay/pushes" }
  let(:tokens) { (1..7).map { |i| "token-#{i}" } }

  before do
    stub_request(:post, relay_url).to_return do |request|
      { body: { results: JSON.parse(request.body)['tokens'].index_with { { status: 'sent' } } }.to_json }
    end
  end

  it 'sends a batch at a time and stops once told to' do
    checks = [true, false]

    outcomes = sender.ring(tokens, { id: 1 }, proceed: -> { checks.shift })

    expect(outcomes).to eq(tokens.first(5).index_with(:sent))
    expect(a_request(:post, relay_url)).to have_been_made.once
  end

  it 'sends nothing when the call stopped ringing before the first batch' do
    expect(sender.ring(tokens, { id: 1 }, proceed: -> { false })).to eq({})
    expect(a_request(:post, relay_url)).not_to have_been_made
  end

  it 'gives the same absolute expiry to every batch' do
    travel_to(Time.zone.at(1_800_000_000)) { sender }
    sender.ring(tokens, { id: 1 })

    expect(a_request(:post, relay_url).with { |request| JSON.parse(request.body)['expires_at'] == 1_800_000_045 }).to have_been_made.twice
  end
end
