require 'rails_helper'

RSpec.describe Avatar::AvatarFromFaviconJob do
  let(:company) { create(:company, domain: 'wikipedia.org') }
  let(:favicon_url) { 'https://www.google.com/s2/favicons?domain=wikipedia.org&sz=256' }

  it 'calls AvatarFromUrlJob with Google Favicon URL' do
    expect(Avatar::AvatarFromUrlJob).to receive(:perform_now).with(company, favicon_url)
    described_class.perform_now(company)
  end

  it 'does not call AvatarFromUrlJob when domain is blank' do
    company.update(domain: '')
    expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_now)
    described_class.perform_now(company)
  end

  it 'does not call AvatarFromUrlJob when avatar is already attached' do
    company.avatar.attach(
      io: Rails.root.join('spec/assets/avatar.png').open,
      filename: 'avatar.png',
      content_type: 'image/png'
    )
    expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_now)
    described_class.perform_now(company)
  end
end
