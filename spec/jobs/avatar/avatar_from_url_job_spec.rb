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

  # ref: https://github.com/chatwoot/chatwoot/issues/10449
  it 'will not throw error if the avatar url is not valid and the file does not have a filename' do
    # Create a temporary file with no filename and content type application/xml
    temp_file = Tempfile.new(['invalid', '.xml'])
    temp_file.write('<invalid>content</invalid>')
    temp_file.rewind

    expect(Down).to receive(:download).with(avatar_url, max_size: 15 * 1024 * 1024)
                                      .and_return(ActionDispatch::Http::UploadedFile.new(tempfile: temp_file, type: 'application/xml'))

    expect { described_class.perform_now(avatarable, avatar_url) }.not_to raise_error

    temp_file.close
    temp_file.unlink # deletes the temp file
  end
end
