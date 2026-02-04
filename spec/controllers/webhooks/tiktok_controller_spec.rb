require 'rails_helper'

RSpec.describe 'Webhooks::TiktokController', type: :request do
  let(:client_secret) { 'test-tiktok-secret' }
  let(:timestamp) { Time.current.to_i }
  let(:event_payload) do
    {
      event: 'im_receive_msg',
      user_openid: 'biz-123',
      content: { conversation_id: 'tt-conv-1' }.to_json
    }
  end

  def signature_for(body)
    OpenSSL::HMAC.hexdigest('SHA256', client_secret, "#{timestamp}.#{body}")
  end

  before do
    InstallationConfig.where(name: 'TIKTOK_APP_SECRET').delete_all
    GlobalConfig.clear_cache
  end

  it 'enqueues the events job for valid signature' do
    allow(Webhooks::TiktokEventsJob).to receive(:perform_later)

    body = event_payload.to_json
    with_modified_env TIKTOK_APP_SECRET: client_secret do
      post '/webhooks/tiktok',
           params: body,
           headers: { 'CONTENT_TYPE' => 'application/json', 'Tiktok-Signature' => "t=#{timestamp},s=#{signature_for(body)}" }
    end

    expect(response).to have_http_status(:success)
    expect(Webhooks::TiktokEventsJob).to have_received(:perform_later)
  end

  it 'delays processing by 2 seconds for echo events' do
    job_double = class_double(Webhooks::TiktokEventsJob)
    allow(Webhooks::TiktokEventsJob).to receive(:set).with(wait: 2.seconds).and_return(job_double)
    allow(job_double).to receive(:perform_later)

    body = event_payload.to_json
    with_modified_env TIKTOK_APP_SECRET: client_secret do
      post '/webhooks/tiktok?event=im_send_msg',
           params: body,
           headers: { 'CONTENT_TYPE' => 'application/json', 'Tiktok-Signature' => "t=#{timestamp},s=#{signature_for(body)}" }
    end

    expect(response).to have_http_status(:success)
    expect(Webhooks::TiktokEventsJob).to have_received(:set).with(wait: 2.seconds)
    expect(job_double).to have_received(:perform_later)
  end

  it 'returns unauthorized for invalid signature' do
    body = event_payload.to_json
    with_modified_env TIKTOK_APP_SECRET: client_secret do
      post '/webhooks/tiktok',
           params: body,
           headers: { 'CONTENT_TYPE' => 'application/json', 'Tiktok-Signature' => "t=#{timestamp},s=#{'0' * 64}" }
    end

    expect(response).to have_http_status(:unauthorized)
  end
end
