require 'rails_helper'

RSpec.describe Companies::EnrichmentService do
  describe '#perform' do
    let(:company) { create(:company, domain: 'example.com') }
    let(:icon_url) { 'https://media.brand.dev/icon.png' }
    let(:wordmark_url) { 'https://media.brand.dev/wordmark.svg' }
    let(:logos) do
      [
        { url: wordmark_url, type: 'logo', mode: 'light' },
        { url: icon_url, type: 'icon', mode: 'has_opaque_background' }
      ]
    end

    before do
      stub_request(:post, described_class::ENDPOINT)
        .to_return(status: 200, body: { brand: { domain: 'example.com', logos: logos } }.to_json,
                   headers: { 'content-type' => 'application/json' })
    end

    context 'when the company has no avatar' do
      it 'attaches the icon logo' do
        expect(Avatar::AvatarFromUrlJob).to receive(:perform_now).with(company, icon_url)

        described_class.new(company).perform
      end

      context 'when there is no icon logo' do
        let(:logos) { [{ url: wordmark_url, type: 'logo', mode: 'light' }] }

        it 'attaches the first logo' do
          expect(Avatar::AvatarFromUrlJob).to receive(:perform_now).with(company, wordmark_url)

          described_class.new(company).perform
        end
      end

      context 'when the brand has no logos' do
        let(:logos) { [] }

        it 'does not attach an avatar' do
          expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_now)

          described_class.new(company).perform
        end
      end
    end

    context 'when the company already has an avatar' do
      let(:company) { create(:company, :with_avatar, domain: 'example.com') }

      it 'keeps the existing avatar' do
        expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_now)

        described_class.new(company).perform
      end

      it 'replaces the avatar when overwrite is true' do
        expect(Avatar::AvatarFromUrlJob).to receive(:perform_now).with(company, icon_url)

        described_class.new(company, overwrite: true).perform
      end
    end
  end
end
