require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS
describe 'Click-to-WhatsApp referral persistence' do
  let(:account) { create(:account) }
  let!(:whatsapp_channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
  let(:referral) do
    {
      source_type: 'ad', source_id: '120248646764170003',
      source_url: 'https://fb.me/7StD2PTRS', headline: 'Converse conosco',
      body: 'SEGURO HONDA: PROTEÇÃO PARA SEGUIR TRANQUILO', media_type: 'video',
      ctwa_clid: 'abc123'
    }
  end

  def payload(with_referral: true, text: 'Quero informações')
    msg = { from: '5534999999999', id: "wamid.#{SecureRandom.hex(4)}", timestamp: '1686042191',
            text: { body: text }, type: 'text' }
    msg[:referral] = referral if with_referral
    {
      messaging_product: 'whatsapp',
      metadata: { display_phone_number: whatsapp_channel.phone_number.delete('+'),
                  phone_number_id: whatsapp_channel.provider_config['phone_number_id'] },
      contacts: [{ profile: { name: 'Thiago' }, wa_id: '5534999999999' }],
      messages: [msg]
    }
  end

  it 'guarda a campanha do anúncio na conversa' do
    described = Whatsapp::IncomingMessageWhatsappCloudService.new(
      inbox: whatsapp_channel.inbox,
      params: { entry: [{ changes: [{ value: payload }] }] }.with_indifferent_access
    )
    described.perform

    campaign = whatsapp_channel.inbox.conversations.last.additional_attributes['campaign']
    expect(campaign).to be_present
    expect(campaign['source_id']).to eq '120248646764170003'
    expect(campaign['source_type']).to eq 'ad'
    expect(campaign['body']).to include 'SEGURO HONDA'
  end

  it 'não inventa campanha quando a mensagem não vem de anúncio' do
    Whatsapp::IncomingMessageWhatsappCloudService.new(
      inbox: whatsapp_channel.inbox,
      params: { entry: [{ changes: [{ value: payload(with_referral: false) }] }] }.with_indifferent_access
    ).perform

    expect(whatsapp_channel.inbox.conversations.last.additional_attributes['campaign']).to be_nil
  end
end
