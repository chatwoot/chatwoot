require 'rails_helper'

RSpec.describe Companies::FetchAvatarsJob do
  let(:account) { create(:account) }
  let!(:company_with_avatar) { create(:company, account: account, domain: 'example.com') }
  let!(:company_without_avatar) { create(:company, account: account, domain: 'wikipedia.org') }
  let!(:company_no_domain) { create(:company, account: account, domain: nil) }

  before do
    # Attach avatar to first company
    company_with_avatar.avatar.attach(
      io: Rails.root.join('spec/assets/avatar.png').open,
      filename: 'avatar.png',
      content_type: 'image/png'
    )
  end

  it 'enqueues the job' do
    expect { described_class.perform_later(account.id) }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when force_refresh is false' do
    it 'queues Avatar::AvatarFromFaviconJob only for companies without avatars' do
      expect(Avatar::AvatarFromFaviconJob).to receive(:perform_later).with(company_without_avatar).once
      expect(Avatar::AvatarFromFaviconJob).not_to receive(:perform_later).with(company_with_avatar)
      expect(Avatar::AvatarFromFaviconJob).not_to receive(:perform_later).with(company_no_domain)

      described_class.perform_now(account.id, force_refresh: false)
    end

    it 'skips companies with nil or empty domains' do
      expect(Avatar::AvatarFromFaviconJob).not_to receive(:perform_later).with(company_no_domain)
      described_class.perform_now(account.id, force_refresh: false)
    end
  end

  context 'when force_refresh is true' do
    it 'queues Avatar::AvatarFromFaviconJob for all companies with domains' do
      expect(Avatar::AvatarFromFaviconJob).to receive(:perform_later).with(company_with_avatar).once
      expect(Avatar::AvatarFromFaviconJob).to receive(:perform_later).with(company_without_avatar).once
      expect(Avatar::AvatarFromFaviconJob).not_to receive(:perform_later).with(company_no_domain)

      described_class.perform_now(account.id, force_refresh: true)
    end

    it 'purges existing avatars before enqueueing' do
      expect(company_with_avatar.avatar).to be_attached

      described_class.perform_now(account.id, force_refresh: true)

      company_with_avatar.reload
      expect(company_with_avatar.avatar).not_to be_attached
    end
  end

  it 'processes companies without errors' do
    expect { described_class.perform_now(account.id, force_refresh: false) }.not_to raise_error
  end
end
