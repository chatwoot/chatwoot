require 'rails_helper'

RSpec.describe 'Rack::Attack throttled response', type: :request do
  let(:env) { { 'REMOTE_ADDR' => '203.0.113.7' } }
  let(:params) { { email: 'throttled@example.com', password: 'wrong-password' } }

  around do |example|
    original_store = Rack::Attack.cache.store
    original_enabled = Rack::Attack.enabled
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    example.run
  ensure
    Rack::Attack.enabled = original_enabled
    Rack::Attack.cache.store = original_store
  end

  it 'returns JSON with a Retry-After header once a throttle trips' do
    travel_to(Time.zone.at(1_699_999_920)) do
      5.times { post '/auth/sign_in', params: params, env: env }
      expect(response).not_to have_http_status(:too_many_requests)

      post '/auth/sign_in', params: params, env: env
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(response.media_type).to eq('application/json')
    expect(response.headers['Retry-After']).to eq('180')
    expect(response.parsed_body).to eq('error' => 'Too many requests. Retry after 180 seconds.', 'retry_after' => 180)
  end

  it 'counts verification attempts per user across alternate encodings of the same token' do
    mfa_token = Mfa::TokenService.new(user: create(:user)).generate_token

    travel_to(Time.zone.at(1_699_999_920)) do
      10.times do |i|
        post '/auth/sign_in', params: { mfa_token: "#{mfa_token}#{'=' * i}", otp_code: '000000' }, env: { 'REMOTE_ADDR' => "198.51.100.#{i + 1}" }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post '/auth/sign_in', params: { mfa_token: "#{mfa_token}===", otp_code: '000000' }, env: { 'REMOTE_ADDR' => '198.51.100.99' }
    end

    expect(response).to have_http_status(:too_many_requests)
  end
end
