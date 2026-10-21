require 'rails_helper'

RSpec.describe Campaigns::RecoverWhatsappCampaignsJob do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:campaign) { create(:campaign, account: account, inbox: channel.inbox) }

  it 'recovers a stale processing campaign at its saved checkpoint' do
    campaign.processing!
    campaign.update!(whatsapp_cursor: 123, updated_at: 16.minutes.ago)

    expect { described_class.perform_now }
      .to have_enqueued_job(Campaigns::SendWhatsappBatchJob).with(campaign, 123)
  end

  it 'does not restart a campaign that is making progress' do
    campaign.processing!

    expect { described_class.perform_now }.not_to have_enqueued_job(Campaigns::SendWhatsappBatchJob)
  end

  it 'does not automatically restart historical campaigns without a checkpoint' do
    campaign.processing!
    campaign.update!(whatsapp_cursor: nil, updated_at: 16.minutes.ago)

    expect { described_class.perform_now }.not_to have_enqueued_job(Campaigns::SendWhatsappBatchJob)
  end

  it 'does not restart completed campaigns' do
    campaign.processing!
    campaign.completed!
    travel 16.minutes do
      expect { described_class.perform_now }.not_to have_enqueued_job(Campaigns::SendWhatsappBatchJob)
    end
  end

  it 'does not enable WhatsApp recovery for SMS campaigns' do
    sms = create(:channel_sms, account: account)
    campaign = create(:campaign, account: account, inbox: sms.inbox)
    campaign.processing!

    expect(campaign.reload.whatsapp_cursor).to be_nil
  end

  it 'does not enable recovery for unsupported WhatsApp providers' do
    channel.update!(provider: 'default')
    campaign.processing!

    expect(campaign.reload.whatsapp_cursor).to be_nil
  end
end
