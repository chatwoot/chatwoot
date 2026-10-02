require 'rails_helper'

RSpec.describe 'Context.dev Webhooks', type: :request do
  let(:document) { create(:captain_document) }
  let(:batch_id) { 'batch-123' }
  let(:secret) { 'whsec_test' }
  let(:event_id) { 'evt-123' }
  let(:event) { 'batch.completed' }
  let(:payload) do
    {
      event: event,
      id: event_id,
      created_at: Time.current.iso8601,
      data: { batch: { id: batch_id } }
    }.to_json
  end
  let(:timestamp) { Time.current.to_i }
  let(:signature) { OpenSSL::HMAC.hexdigest('SHA256', secret, "#{timestamp}.#{payload}") }
  let(:headers) do
    {
      'CONTENT_TYPE' => 'application/json',
      'X-Context-Event' => event,
      'X-Context-Id' => event_id,
      'X-Context-Signature' => "t=#{timestamp},v1=#{signature}"
    }
  end

  before do
    document.update!(web_crawling_external_id: batch_id, web_crawling_webhook_secret: secret)
  end

  it 'enqueues the signed batch completion for parsing' do
    expect(Captain::Tools::ContextDevParserJob).to receive(:perform_later).with(
      document_id: document.id,
      batch_id: batch_id,
      event: event
    )

    post "/enterprise/webhooks/context_dev?document_id=#{document.id}", params: payload, headers: headers

    expect(response).to have_http_status(:ok)
  end

  it 'rejects an invalid signature' do
    headers['X-Context-Signature'] = "t=#{timestamp},v1=invalid"

    post "/enterprise/webhooks/context_dev?document_id=#{document.id}", params: payload, headers: headers

    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects a mismatched batch identifier' do
    document.update!(web_crawling_external_id: 'another-batch')

    post "/enterprise/webhooks/context_dev?document_id=#{document.id}", params: payload, headers: headers

    expect(response).to have_http_status(:bad_request)
  end
end
