require 'rails_helper'

RSpec.describe Avatar::AvatarFromUrlJob do
  it 'enqueues the job' do
    contact = create(:contact)
    expect { described_class.perform_later(contact, 'https://example.com/avatar.png') }
      .to have_enqueued_job(described_class).on_queue('purgable')
  end
  let(:valid_url) { 'https://example.com/avatar.png' }
  let(:file) { fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }

  context 'rate_limited_avatarable' do
    let(:avatarable) { create(:contact) }

    it 'attaches and updates sync attributes' do
      expect(Down).to receive(:download).with(valid_url, max_size: 15 * 1024 * 1024).and_return(file)
      described_class.perform_now(avatarable, valid_url)
      avatarable.reload
      expect(avatarable.avatar).to be_attached
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(valid_url))
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_present
    end

    it 'returns early when rate limited' do
      ts = 30.seconds.ago.iso8601
      avatarable.update(additional_attributes: { 'last_avatar_sync_at' => ts })
      expect(Down).not_to receive(:download)
      described_class.perform_now(avatarable, valid_url)
      avatarable.reload
      expect(avatarable.avatar).not_to be_attached
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to eq(ts)
    end

    it 'returns early when hash unchanged' do
      avatarable.update(additional_attributes: { 'avatar_url_hash' => Digest::SHA256.hexdigest(valid_url) })
      expect(Down).not_to receive(:download)
      described_class.perform_now(avatarable, valid_url)
      expect(avatarable.avatar).not_to be_attached
    end
  end

  context 'regular_avatarable' do
    let(:avatarable) { create(:agent_bot) }

    it 'downloads and attaches avatar' do
      expect(Down).to receive(:download).with(valid_url, max_size: 15 * 1024 * 1024).and_return(file)
      described_class.perform_now(avatarable, valid_url)
      expect(avatarable.avatar).to be_attached
    end
  end

  # ref: https://github.com/chatwoot/chatwoot/issues/10449
  it 'does not raise error when downloaded file has no filename (invalid content)' do
    contact = create(:contact)
    temp_file = Tempfile.new(['invalid', '.xml'])
    temp_file.write('<invalid>content</invalid>')
    temp_file.rewind

    expect(Down).to receive(:download).with(valid_url, max_size: 15 * 1024 * 1024)
                                      .and_return(ActionDispatch::Http::UploadedFile.new(tempfile: temp_file, type: 'application/xml'))

    expect { described_class.perform_now(contact, valid_url) }.not_to raise_error

    temp_file.close
    temp_file.unlink
  end
end
