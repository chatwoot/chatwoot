require 'rails_helper'

RSpec.describe WebCrawling::ContextDev::WebhookVerifier do
  let(:payload) { { event: 'batch.completed' }.to_json }
  let(:secret) { 'whsec_test' }
  let(:timestamp) { Time.current.to_i }
  let(:digest) { OpenSSL::HMAC.hexdigest('SHA256', secret, "#{timestamp}.#{payload}") }

  it 'accepts a current signature over the raw request body' do
    verifier = described_class.new(payload: payload, signature: "t=#{timestamp},v1=#{digest}", secret: secret)

    expect(verifier.valid?).to be(true)
  end

  it 'rejects a stale signature' do
    stale_timestamp = 10.minutes.ago.to_i
    stale_digest = OpenSSL::HMAC.hexdigest('SHA256', secret, "#{stale_timestamp}.#{payload}")
    verifier = described_class.new(payload: payload, signature: "t=#{stale_timestamp},v1=#{stale_digest}", secret: secret)

    expect(verifier.valid?).to be(false)
  end

  it 'rejects a signature for a different body' do
    verifier = described_class.new(payload: '{}', signature: "t=#{timestamp},v1=#{digest}", secret: secret)

    expect(verifier.valid?).to be(false)
  end
end
