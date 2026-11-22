require 'rails_helper'

RSpec.describe Whatsapp::DeclineCallJob do
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:provider_service) { instance_double(Whatsapp::Providers::WhatsappCloudService) }

  before { allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_service) }

  it 'declines the call at Meta' do
    allow(provider_service).to receive(:reject_call).and_return(true)

    expect { described_class.perform_now(inbox, 'wacid_1') }.not_to have_enqueued_job(described_class)
    expect(provider_service).to have_received(:reject_call).with('wacid_1')
  end

  it 'tries again when Meta refuses the decline' do
    allow(provider_service).to receive(:reject_call).and_return(false)

    expect { described_class.perform_now(inbox, 'wacid_1') }.to have_enqueued_job(described_class).with(inbox, 'wacid_1')
  end

  it 'tries again when Meta cannot be reached' do
    allow(provider_service).to receive(:reject_call).and_raise(Net::OpenTimeout)

    expect { described_class.perform_now(inbox, 'wacid_1') }.to have_enqueued_job(described_class).with(inbox, 'wacid_1')
  end
end
