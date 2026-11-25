require 'rails_helper'

RSpec.describe 'Webhooks::Whatsapp::UazapiController', type: :request do
  let(:channel) { create(:channel_whatsapp, provider: 'uazapi', sync_templates: false, validate_provider_config: false) }
  let(:webhook_token) { channel.provider_config['webhook_verify_token'] }
  let(:instance_token) { channel.provider_config['token'] }
  let(:body) { { 'EventType' => 'connection', 'token' => instance_token, 'instance' => { 'status' => 'connected' } } }

  def post_webhook(path, payload)
    post path, params: payload.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }
  end

  def webhook_path(id: channel.id, token: webhook_token)
    "/webhooks/whatsapp/session/uazapi/#{id}/#{token}"
  end

  it 'queues the events of an authentic delivery, naming the instance they came from' do
    fingerprint = Whatsapp::Session::Registry.instance_fingerprint(channel)

    expect { post_webhook(webhook_path, body) }
      .to have_enqueued_job(Webhooks::WhatsappSessionEventsJob)
      .with(channel, hash_including('EventType' => 'connection'), fingerprint)

    expect(response).to have_http_status(:ok)
  end

  # The token has done its job by the time the body is queued, and leaving it in would
  # carry the credential into a job argument, its retries and whatever logs those pass.
  it 'strips the instance credential before the body goes anywhere' do
    expect { post_webhook(webhook_path, body) }
      .to have_enqueued_job(Webhooks::WhatsappSessionEventsJob)
      .with(channel, satisfy { |payload| payload.exclude?('token') }, anything)
  end

  # Two independent secrets: one proves the caller was told where to post, the other that
  # it is the instance this inbox is configured for. Either alone is not enough.
  it 'refuses a body whose instance token is not the one this inbox uses' do
    expect { post_webhook(webhook_path, body.merge('token' => 'someone-elses-instance')) }
      .not_to have_enqueued_job(Webhooks::WhatsappSessionEventsJob)

    expect(response).to have_http_status(:unauthorized)
  end

  it 'refuses a url whose secret is not this inbox’s' do
    post_webhook(webhook_path(token: SecureRandom.hex(16)), body)

    expect(response).to have_http_status(:unauthorized)
  end

  it 'refuses a body with no token at all' do
    post_webhook(webhook_path, body.except('token'))

    expect(response).to have_http_status(:unauthorized)
  end

  it 'answers not found for an inbox that is not on this provider' do
    other = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)

    post_webhook(webhook_path(id: other.id), body)

    expect(response).to have_http_status(:not_found)
  end

  # A body this build cannot read is the translator's business. Answering anything but a
  # 2xx here would have the provider redeliver it for as long as it keeps trying.
  it 'accepts an event type it does not understand' do
    post_webhook(webhook_path, { 'EventType' => 'labels', 'token' => instance_token })

    expect(response).to have_http_status(:ok)
  end
end
