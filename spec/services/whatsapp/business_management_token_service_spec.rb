require 'rails_helper'

RSpec.describe Whatsapp::BusinessManagementTokenService do
  let(:channel) do
    create(
      :channel_whatsapp,
      provider: 'whatsapp_cloud',
      provider_config: {
        'api_key' => 'integration-token',
        'phone_number_id' => 'phone-id',
        'business_account_id' => 'waba-id',
        'source' => 'embedded_signup'
      },
      sync_templates: false,
      validate_provider_config: false
    )
  end
  let(:service) { described_class.new(channel) }
  let(:validation_service) { instance_double(Whatsapp::BusinessManagementTokenValidationService, perform: true) }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    allow(Whatsapp::BusinessManagementTokenValidationService).to receive(:new).with('business-token').and_return(validation_service)
  end

  it 'stores the business management token without replacing the API key' do
    original_api_key = channel.provider_config['api_key']

    service.update!('business-token')

    expect(channel.reload.business_management_token).to eq('business-token')
    expect(channel.provider_config['api_key']).to eq(original_api_key)
  end

  it 'stores the token without revalidating the existing provider API key' do
    expect(channel).not_to receive(:validate_provider_config)

    service.update!('business-token')
  end

  it 'removes the token so template synchronization falls back to the API key' do
    channel.business_management_token = 'business-token'
    channel.save!(validate: false)

    service.remove!

    expect(channel.reload.business_management_token).to be_nil
    expect(channel.template_access_token).to eq(channel.provider_config['api_key'])
  end

  it 'rejects updates outside Chatwoot Cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

    expect { service.update!('business-token') }
      .to raise_error(ArgumentError, 'Business management token is only available on Chatwoot Cloud')
    expect(validation_service).not_to have_received(:perform)
  end

  it 'rejects updates for manually configured WhatsApp Cloud inboxes' do
    channel.provider_config.delete('source')

    expect { service.update!('business-token') }
      .to raise_error(ArgumentError, 'Business management token is only supported for WhatsApp Embedded Signup inboxes')
    expect(validation_service).not_to have_received(:perform)
  end
end
