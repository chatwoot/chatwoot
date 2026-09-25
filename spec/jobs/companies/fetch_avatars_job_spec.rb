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

  it 'queues Avatar::AvatarFromFaviconJob only for companies without avatars' do
    expect(Avatar::AvatarFromFaviconJob).to receive(:perform_later).with(company_without_avatar).once
    expect(Avatar::AvatarFromFaviconJob).not_to receive(:perform_later).with(company_with_avatar)
    expect(Avatar::AvatarFromFaviconJob).not_to receive(:perform_later).with(company_no_domain)

    described_class.perform_now(account.id)
  end
end
