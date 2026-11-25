require 'rails_helper'

RSpec.describe 'Webhooks::ResendController', type: :request do
  let(:key) { 'resend-test-signing-key' }
  let(:secret) { "whsec_#{Base64.strict_encode64(key)}" }
  let(:svix_id) { 'msg_2abc' }
  let(:timestamp) { Time.current.to_i }
  let(:body) { { type: 'email.received', data: { email_id: 'em_123' } }.to_json }
  let(:signature) { Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', key, "#{svix_id}.#{timestamp}.#{body}")) }

  def deliver(signature_header)
    with_modified_env RESEND_INBOUND_WEBHOOK_SECRET: secret do
      post '/webhooks/resend/inbound',
           params: body,
           headers: { 'CONTENT_TYPE' => 'application/json', 'svix-id' => svix_id, 'svix-timestamp' => timestamp.to_s,
                      'svix-signature' => signature_header }
    end
  end

  before { allow(Webhooks::ResendInboundEmailJob).to receive(:perform_later) }

  it 'enqueues the received email when one of the listed signatures matches' do
    deliver("v1,c29tZXRoaW5nZWxzZQ== v1,#{signature}")

    expect(response).to have_http_status(:ok)
    expect(Webhooks::ResendInboundEmailJob).to have_received(:perform_later).with('em_123')
  end

  context 'when the event is not email.received' do
    let(:body) { { type: 'email.delivered', data: { email_id: 'em_123' } }.to_json }

    it 'acknowledges it without enqueuing anything' do
      deliver("v1,#{signature}")

      expect(response).to have_http_status(:ok)
      expect(Webhooks::ResendInboundEmailJob).not_to have_received(:perform_later)
    end
  end

  it 'rejects a signature made with another key' do
    deliver("v1,#{Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', 'other', "#{svix_id}.#{timestamp}.#{body}"))}")

    expect(response).to have_http_status(:unauthorized)
    expect(Webhooks::ResendInboundEmailJob).not_to have_received(:perform_later)
  end

  context 'when the installation has no signing secret' do
    let(:secret) { '' }
    let(:key) { '' }

    it 'rejects a signature made with an empty key' do
      deliver("v1,#{signature}")

      expect(response).to have_http_status(:unauthorized)
      expect(Webhooks::ResendInboundEmailJob).not_to have_received(:perform_later)
    end
  end

  context 'when the timestamp is older than the tolerance' do
    let(:timestamp) { 10.minutes.ago.to_i }

    it 'rejects the replay' do
      deliver("v1,#{signature}")

      expect(response).to have_http_status(:unauthorized)
      expect(Webhooks::ResendInboundEmailJob).not_to have_received(:perform_later)
    end
  end
end
