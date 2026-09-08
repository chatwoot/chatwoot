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
end
