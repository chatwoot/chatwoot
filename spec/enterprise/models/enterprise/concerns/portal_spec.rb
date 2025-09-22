require 'rails_helper'

RSpec.describe Enterprise::Concerns::Portal do
  describe '#enqueue_cloudflare_verification' do
    let(:portal) { create(:portal, custom_domain: nil) }

    context 'when custom_domain is changed' do
      context 'when on chatwoot cloud' do
        before do
          allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        end

        it 'enqueues cloudflare verification job' do
          expect do
            portal.update(custom_domain: 'test.example.com')
          end.to have_enqueued_job(Enterprise::CloudflareVerificationJob).with(portal.id)
        end
      end

      context 'when not on chatwoot cloud' do
        before do
          allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
        end

        it 'does not enqueue cloudflare verification job' do
          expect do
            portal.update(custom_domain: 'test.example.com')
          end.not_to have_enqueued_job(Enterprise::CloudflareVerificationJob)
        end
      end
    end

    context 'when custom_domain is not changed' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        portal.update(custom_domain: 'test.example.com')
      end

      it 'does not enqueue cloudflare verification job' do
        expect do
          portal.update(name: 'New Name')
        end.not_to have_enqueued_job(Enterprise::CloudflareVerificationJob)
      end
    end

    context 'when custom_domain is set to blank' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        portal.update(custom_domain: 'test.example.com')
      end

      it 'does not enqueue cloudflare verification job' do
        expect do
          portal.update(custom_domain: '')
        end.not_to have_enqueued_job(Enterprise::CloudflareVerificationJob)
      end
    end
  end
end
