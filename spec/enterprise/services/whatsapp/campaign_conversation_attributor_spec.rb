require 'rails_helper'

RSpec.describe Whatsapp::CampaignConversationAttributor do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: account, phone_number: '+16503071063') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '16503071063') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }
  let(:campaign) { create(:campaign, :whatsapp, account: account, inbox: inbox, campaign_type: :one_off) }
  let(:context_id) { 'wamid.ORIGINAL_MESSAGE_ID' }
  let(:message_payload) do
    {
      context: { from: '16503071063', id: context_id },
      from: '16503071063',
      id: 'wamid.REPLY_MESSAGE_ID',
      text: { body: 'Yes' },
      type: 'text'
    }.with_indifferent_access
  end

  before { account.enable_features!(:whatsapp_campaign) }

  def perform_attribution
    described_class.new(
      conversation: conversation,
      inbox: inbox,
      message_payload: message_payload,
      outgoing_echo: false
    ).perform
  end

  it 'sets campaign_id when context.id matches a campaign recipient' do
    CampaignRecipient.create!(
      account: account,
      campaign: campaign,
      contact: contact,
      inbox: inbox,
      status: :sent,
      source_id: context_id
    )

    perform_attribution

    expect(conversation.reload.campaign_id).to eq(campaign.id)
  end

  it 'does not change campaign_id when context is missing' do
    CampaignRecipient.create!(
      account: account,
      campaign: campaign,
      contact: contact,
      inbox: inbox,
      status: :sent,
      source_id: context_id
    )
    payload = message_payload.except(:context)

    described_class.new(
      conversation: conversation,
      inbox: inbox,
      message_payload: payload,
      outgoing_echo: false
    ).perform

    expect(conversation.reload.campaign_id).to be_nil
  end

  it 'does not overwrite an existing campaign_id' do
    other_campaign = create(:campaign, :whatsapp, account: account, inbox: inbox, campaign_type: :one_off, title: 'Other')
    conversation.update!(campaign_id: other_campaign.id)
    CampaignRecipient.create!(
      account: account,
      campaign: campaign,
      contact: contact,
      inbox: inbox,
      status: :sent,
      source_id: context_id
    )

    perform_attribution

    expect(conversation.reload.campaign_id).to eq(other_campaign.id)
  end

  it 'does not attribute from a recipient in another inbox' do
    other_channel = create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false)
    other_campaign = create(:campaign, :whatsapp, account: account, inbox: other_channel.inbox, campaign_type: :one_off)
    CampaignRecipient.create!(
      account: account,
      campaign: other_campaign,
      contact: contact,
      inbox: other_channel.inbox,
      status: :sent,
      source_id: context_id
    )

    perform_attribution

    expect(conversation.reload.campaign_id).to be_nil
  end
end
