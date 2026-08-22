require 'rails_helper'

RSpec.describe Enterprise::Whatsapp::IncomingMessageBaseService do
  let(:channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
  let(:status) do
    {
      'id' => 'wamid.not-persisted-yet',
      'status' => 'delivered',
      'timestamp' => '1700000600'
    }
  end

  before { channel.account.enable_features!(:whatsapp_campaign) }

  it 'defers a campaign status when neither a recipient nor a message is persisted yet' do
    expect do
      Whatsapp::IncomingMessageService.new(
        inbox: channel.inbox,
        params: { 'statuses' => [status] }.with_indifferent_access
      ).perform
    end.to have_enqueued_job(Campaigns::UpdateRecipientStatusJob).with(channel.inbox.id, status).on_queue('low')
  end

  it 'does not update a recipient from another inbox' do
    other_account = create(:account)
    other_channel = create(:channel_whatsapp, account: other_account, sync_templates: false, validate_provider_config: false)
    other_campaign = create(:campaign, account: other_account, inbox: other_channel.inbox, campaign_type: :one_off)
    other_recipient = CampaignRecipient.create!(
      account: other_account,
      campaign: other_campaign,
      contact: create(:contact, account: other_account),
      inbox: other_channel.inbox,
      status: :sent,
      source_id: status['id']
    )

    Whatsapp::IncomingMessageService.new(
      inbox: channel.inbox,
      params: { 'statuses' => [status] }.with_indifferent_access
    ).perform

    expect(other_recipient.reload).to be_sent
  end

  describe 'campaign conversation attribution' do
    let(:contact) { create(:contact, account: channel.account, phone_number: '+16503071063') }
    let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: channel.inbox, source_id: '16503071063') }
    let(:campaign) { create(:campaign, :whatsapp, account: channel.account, inbox: channel.inbox, campaign_type: :one_off) }
    let(:reply_params) do
      {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              contacts: [{ profile: { name: 'Pranav' }, wa_id: '16503071063' }],
              messages: [{
                context: { from: '16503071063', id: 'wamid.CAMPAIGN_TEMPLATE' },
                from: '16503071063',
                id: 'wamid.REPLY_MESSAGE_ID',
                timestamp: '1770407829',
                text: { body: 'Yes' },
                type: 'text'
              }]
            }
          }]
        }]
      }.with_indifferent_access
    end

    it 'attributes the conversation when the reply references a campaign recipient' do
      CampaignRecipient.create!(
        account: channel.account,
        campaign: campaign,
        contact: contact,
        inbox: channel.inbox,
        status: :sent,
        source_id: 'wamid.CAMPAIGN_TEMPLATE'
      )

      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: reply_params).perform

      conversation = channel.inbox.conversations.last
      expect(conversation.campaign_id).to eq(campaign.id)
    end
  end
end
