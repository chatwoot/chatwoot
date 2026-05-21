require 'rails_helper'

RSpec.describe Enterprise::CloudflareVerificationJob do
  let(:portal) { create(:portal, custom_domain: 'test.example.com') }

  describe '#perform' do
    context 'when portal is not found' do
      it 'returns early' do
        expect(Portal).to receive(:find).with(0).and_return(nil)
        expect(Cloudflare::CheckCustomHostnameService).not_to receive(:new)
        expect(Cloudflare::CreateCustomHostnameService).not_to receive(:new)

        described_class.perform_now(0)
      end
    end

    context 'when portal has no custom domain' do
      it 'returns early' do
        portal_without_domain = create(:portal, custom_domain: nil)
        expect(Cloudflare::CheckCustomHostnameService).not_to receive(:new)
        expect(Cloudflare::CreateCustomHostnameService).not_to receive(:new)

        described_class.perform_now(portal_without_domain.id)
      end
    end

    context 'when portal exists with custom domain' do
      it 'checks hostname status' do
        check_service = instance_double(Cloudflare::CheckCustomHostnameService, perform: { data: 'success' })
        expect(Cloudflare::CheckCustomHostnameService).to receive(:new).with(portal: portal).and_return(check_service)
        expect(Cloudflare::CreateCustomHostnameService).not_to receive(:new)

        described_class.perform_now(portal.id)
      end

      it 'creates hostname when check returns errors' do
        check_service = instance_double(Cloudflare::CheckCustomHostnameService, perform: { errors: ['Hostname is missing'] })
        create_service = instance_double(Cloudflare::CreateCustomHostnameService, perform: { data: 'success' })

        expect(Cloudflare::CheckCustomHostnameService).to receive(:new).with(portal: portal).and_return(check_service)
        expect(Cloudflare::CreateCustomHostnameService).to receive(:new).with(portal: portal).and_return(create_service)

        described_class.perform_now(portal.id)
      end
    end
  end
end
