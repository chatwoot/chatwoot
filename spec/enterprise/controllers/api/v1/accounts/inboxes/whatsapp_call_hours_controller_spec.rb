require 'rails_helper'

RSpec.describe 'WhatsApp call hours API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:url) { "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/whatsapp_call_hours" }
  let(:settings_url) { 'https://graph.facebook.com/v22.0/123456789/settings' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  before do
    account.enable_features!('channel_voice')
    channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => true, 'business_hours_calls_enabled' => true))
    channel.inbox.update!(working_hours_enabled: true)
  end

  def stub_meta_call_hours(call_hours)
    stub_request(:get, settings_url).to_return(status: 200, headers: headers, body: { calling: { call_hours: call_hours } }.to_json)
  end

  describe 'GET' do
    it 'says whether WhatsApp has the inbox hours' do
      stub_meta_call_hours('status' => 'DISABLED')

      get url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq('matches_whatsapp' => false)
    end

    it "returns WhatsApp's error when the hours can't be read" do
      stub_request(:get, settings_url).to_return(status: 400, headers: headers, body: { error: { error_user_msg: 'Token expired' } }.to_json)

      get url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Token expired')
    end

    it 'is only for administrators' do
      get url, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'needs WhatsApp calling on' do
      channel.update!(provider_config: channel.provider_config.merge('calling_enabled' => false))

      get url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH' do
    it 'applies the inbox hours to WhatsApp' do
      stub_meta_call_hours('status' => 'DISABLED')
      update = stub_request(:post, settings_url)
               .with { |request| JSON.parse(request.body).dig('calling', 'call_hours', 'status') == 'ENABLED' }
               .to_return(status: 200, body: '{}')

      patch url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(update).to have_been_requested
    end

    it 'sends the setting as saved when the lock is taken, so a disable saved meanwhile wins' do
      stub_meta_call_hours('status' => 'ENABLED')
      sent = []
      stub_request(:post, settings_url).with { |request| sent << JSON.parse(request.body).dig('calling', 'call_hours', 'status') }
                                       .to_return(status: 200, body: '{}')
      allow_any_instance_of(Channel::Whatsapp).to receive(:lock!).and_wrap_original do |original, *args| # rubocop:disable RSpec/AnyInstance
        saved = Channel::Whatsapp.find(channel.id)
        saved.provider_config = saved.provider_config.merge('business_hours_calls_enabled' => false)
        saved.save!(validate: false)
        original.call(*args)
      end

      patch url, headers: admin.create_new_auth_token, as: :json

      expect(sent).to eq(['DISABLED'])
    end

    it "returns WhatsApp's reason when it refuses the hours" do
      stub_meta_call_hours('status' => 'DISABLED')
      stub_request(:post, settings_url).to_return(status: 400, headers: headers, body: { error: { error_user_msg: 'Invalid timezone_id' } }.to_json)

      patch url, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['message']).to eq(I18n.t('inbox.call_hours.whatsapp_failed', error: 'Invalid timezone_id'))
    end
  end
end
