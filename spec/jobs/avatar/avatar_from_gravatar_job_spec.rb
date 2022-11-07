require 'rails_helper'

RSpec.describe Avatar::AvatarFromGravatarJob, type: :job do
  let(:avatarable) { create(:contact) }
  let(:email) { 'test@test.com' }
  let(:gravatar_url) { "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}?d=404" }

  it 'enqueues the job' do
    expect { described_class.perform_later(avatarable, email) }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  it 'will call AvatarFromUrlJob with gravatar url' do
    expect(Avatar::AvatarFromUrlJob).to receive(:perform_later).with(avatarable, gravatar_url)
    described_class.perform_now(avatarable, email)
  end

  it 'will not call AvatarFromUrlJob if DISABLE_GRAVATAR is configured' do
    with_modified_env DISABLE_GRAVATAR: 'true' do
      expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later).with(avatarable, gravatar_url)
      described_class.perform_now(avatarable, '')
    end
  end

  it 'will not call AvatarFromUrlJob if email is blank' do
    expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later).with(avatarable, gravatar_url)
    described_class.perform_now(avatarable, '')
  end
end
