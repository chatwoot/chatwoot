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
    end.to have_enqueued_job(Campaigns::UpdateRecipientStatusJob).with(status).on_queue('low')
  end
end
