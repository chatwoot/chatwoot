require 'rails_helper'

RSpec.describe Whatsapp::ReauthorizationService do
  let(:account) { create(:account) }
  let(:channel) do
    create(
      :channel_whatsapp,
      account: account,
      provider: 'whatsapp_cloud',
      provider_config: {
        'api_key' => 'old-token',
        'phone_number_id' => 'old-phone-id',
        'business_account_id' => 'old-waba-id',
        'source' => 'embedded_signup',
        'disconnection_reason' => 'PRIMARY_INACTIVITY'
      },
      business_management_token: 'business-token',
      message_templates: [{ 'name' => 'old_template' }],
      validate_provider_config: false,
      sync_templates: false
    )
  end
  let(:inbox) { create(:inbox, account: account, channel: channel) }
  let(:phone_info) { { phone_number: channel.phone_number, business_name: inbox.name } }

  before do
    stub_request(:get, %r{\Ahttps://graph\.facebook\.com/v14\.0/.+/message_templates\?access_token=new-token\z})
      .to_return(status: 200, body: { data: [] }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, %r{\Ahttps://graph\.facebook\.com/v14\.0/.+/phone_numbers\?.*access_token=new-token})
      .to_return(status: 200, body: { data: [{ id: 'new-phone-id' }] }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'clears the business management token when the WhatsApp Business Account changes' do
    described_class.new(
      account: account,
      inbox_id: inbox.id,
      phone_number_id: 'new-phone-id',
      waba_id: 'new-waba-id'
    ).perform('new-token', phone_info)

    expect(channel.reload.business_management_token).to be_nil
  end

  it 'retains the business management token when the WhatsApp Business Account does not change' do
    described_class.new(
      account: account,
      inbox_id: inbox.id,
      phone_number_id: 'new-phone-id',
      waba_id: channel.provider_config['business_account_id']
    ).perform('new-token', phone_info)

    expect(channel.reload.business_management_token).to eq('business-token')
  end

  it 'clears the disconnection reason Meta sent when it removed our access' do
    described_class.new(
      account: account,
      inbox_id: inbox.id,
      phone_number_id: 'new-phone-id',
      waba_id: channel.provider_config['business_account_id']
    ).perform('new-token', phone_info)

    expect(channel.reload.provider_config).not_to have_key('disconnection_reason')
  end

  context 'with templates synced from the previous Messaging account' do
    it 'clears them and resyncs when the Messaging account changes' do
      expect do
        described_class.new(
          account: account,
          inbox_id: inbox.id,
          phone_number_id: 'new-phone-id',
          waba_id: 'new-waba-id'
        ).perform('new-token', phone_info)
      end.to have_enqueued_job(Channels::Whatsapp::TemplatesSyncJob).with(channel)

      expect(channel.reload.message_templates).to eq({})
    end

    it 'keeps them when the Messaging account does not change' do
      expect do
        described_class.new(
          account: account,
          inbox_id: inbox.id,
          phone_number_id: 'new-phone-id',
          waba_id: channel.provider_config['business_account_id']
        ).perform('new-token', phone_info)
      end.not_to have_enqueued_job(Channels::Whatsapp::TemplatesSyncJob)

      expect(channel.reload.message_templates).to eq([{ 'name' => 'old_template' }])
    end
  end
end
