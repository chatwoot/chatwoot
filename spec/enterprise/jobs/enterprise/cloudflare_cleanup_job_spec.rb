require 'rails_helper'

RSpec.describe CloudflareCleanupJob, type: :job do
  let(:list_service) { instance_double(Cloudflare::ListCustomHostnamesService) }
  let(:delete_service) { instance_double(Cloudflare::DeleteCustomHostnameService) }

  before do
    allow(Cloudflare::ListCustomHostnamesService).to receive(:new).and_return(list_service)
    allow(Cloudflare::DeleteCustomHostnameService).to receive(:new).and_return(delete_service)
  end

  describe '#perform' do
    context 'when not chatwoot cloud' do
      it 'skips cleanup' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)

        expect(list_service).not_to receive(:perform)
        described_class.perform_now
      end
    end

    context 'when chatwoot cloud' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      end

      it 'calls list service and processes results' do
        allow(list_service).to receive(:perform).and_return({ data: [] })

        described_class.perform_now

        expect(list_service).to have_received(:perform)
      end

      it 'calls delete service for orphaned hostnames' do
        create(:portal, custom_domain: 'existing.com')
        hostnames = [
          { 'id' => 'keep-id', 'hostname' => 'existing.com' },
          { 'id' => 'delete-id', 'hostname' => 'orphaned.com' }
        ]

        allow(list_service).to receive(:perform).and_return({ data: hostnames })
        allow(delete_service).to receive(:perform).and_return({ success: true })

        described_class.perform_now

        expect(Cloudflare::DeleteCustomHostnameService).to have_received(:new)
          .with(hostname_id: 'delete-id')
        expect(delete_service).to have_received(:perform)
      end
    end
  end
end
