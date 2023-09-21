require 'rails_helper'

RSpec.describe Avatar::AvatarFromUrlJob do
  let(:avatarable) { create(:contact) }
  let(:avatar_url) { 'https://example.com/avatar.png' }

  it 'enqueues the job' do
    expect { described_class.perform_later(avatarable, avatar_url) }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  it 'will attach avatar from url' do
    expect(avatarable.avatar).not_to be_attached
    expect(Down).to receive(:download).with(avatar_url,
                                            max_size: 15 * 1024 * 1024).and_return(fixture_file_upload(Rails.root.join('spec/assets/avatar.png'),
                                                                                                       'image/png'))
    described_class.perform_now(avatarable, avatar_url)
    expect(avatarable.avatar).to be_attached
  end
end
