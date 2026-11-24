require 'rails_helper'

RSpec.describe Channel::Whatsapp do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:settings_url) { 'https://graph.facebook.com/v22.0/123456789/settings' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  before { account.enable_features!('channel_voice') }

  def stub_callback_permission(status, response_status: 200)
    body = response_status == 200 ? { success: true } : { error: { error_user_msg: 'Callback permission is not available' } }
    stub_request(:post, settings_url).with(body: { calling: { callback_permission_status: status } }.to_json)
                                     .to_return(status: response_status, headers: headers, body: body.to_json)
  end

  describe '#update_callback_permission!' do
    it 'turns the setting on at WhatsApp and saves it' do
      update = stub_callback_permission('ENABLED')

      channel.update_callback_permission!(true)

      expect(update).to have_been_requested
      expect(channel.reload.provider_config['callback_permission_enabled']).to be(true)
    end

    it "keeps the saved setting when WhatsApp refuses it, and raises WhatsApp's reason" do
      stub_callback_permission('DISABLED', response_status: 400)
      channel.update!(provider_config: channel.provider_config.merge('callback_permission_enabled' => true))

      expect { channel.update_callback_permission!(false) }.to raise_error('Callback permission is not available')
      expect(channel.reload.provider_config['callback_permission_enabled']).to be(true)
    end
  end

  describe '#enable_voice_calling!' do
    before do
      allow(channel).to receive(:webhook_setup_service).and_return(instance_double(Whatsapp::WebhookSetupService, register_callback: true))
      stub_request(:post, settings_url).with(body: { calling: { status: 'ENABLED' } }.to_json)
                                       .to_return(status: 200, headers: headers, body: '{}')
    end

    it 'asks callers for permission to call back by default' do
      update = stub_callback_permission('ENABLED')

      channel.enable_voice_calling!

      expect(update).to have_been_requested
      expect(channel.reload.provider_config).to include('calling_enabled' => true, 'callback_permission_enabled' => true)
    end

    it 'leaves it off when an admin turned it off before' do
      channel.update!(provider_config: channel.provider_config.merge('callback_permission_enabled' => false))

      channel.enable_voice_calling!

      expect(a_request(:post, settings_url).with(body: /callback_permission_status/)).not_to have_been_made
      expect(channel.reload.provider_config).to include('calling_enabled' => true, 'callback_permission_enabled' => false)
    end

    it 'still turns calling on when WhatsApp refuses the callback setting, showing it as off' do
      stub_callback_permission('ENABLED', response_status: 400)

      channel.enable_voice_calling!

      expect(channel.reload.provider_config['calling_enabled']).to be(true)
      expect(channel.provider_config).not_to have_key('callback_permission_enabled')
    end
  end
end
