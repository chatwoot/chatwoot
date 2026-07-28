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
    allow(channel).to receive(:provider_service)
      .and_return(instance_double(Whatsapp::Providers::WhatsappCloudService, validate_provider_config?: true))
  end

  it 'stores the business management token without replacing the API key' do
    service.update!('business-token')

    expect(channel.reload.business_management_token).to eq('business-token')
    expect(channel.provider_config['api_key']).to eq('test_key')
  end

  it 'rejects updates outside Chatwoot Cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

    expect { service.update!('business-token') }
      .to raise_error(ArgumentError, 'Business management token is only available on Chatwoot Cloud')
    expect(validation_service).not_to have_received(:perform)
  end
end
