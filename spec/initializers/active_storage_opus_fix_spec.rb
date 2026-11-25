require 'rails_helper'

# rubocop:disable RSpec/SpecFilePathFormat -- the subject is the patch, which lives in
# config/initializers/active_storage_opus_fix.rb; mirroring that path is the point.
describe ActiveStorage::Blob do
  # A real Ogg Opus file, which is what a WhatsApp voice note is. Marcel identifies it as
  # audio/opus off the magic bytes `OggS` + `OpusHead`, and WhatsApp Cloud rejects that type
  # with 131053 (measured live: the same bytes served as audio/ogg are delivered and played).
  let(:opus_path) { Rails.root.join('spec/assets/sample_opus.ogg') }

  def uploaded_content_types
    captured = []
    allow(described_class.service).to receive(:upload).and_wrap_original do |original, *args, **kwargs|
      captured << kwargs[:content_type]
      original.call(*args, **kwargs)
    end
    yield
    captured
  end

  # The path a multipart upload takes: MessageBuilder hands an UploadedFile to `attach`, which
  # unfurls the io and asks `extract_content_type`. It is the identification the object in the
  # bucket is written with, so getting it wrong here is what the storage keeps.
  describe 'identification when the file is attached from an io' do
    it 'stores an Ogg Opus recording as audio/ogg' do
      blob = described_class.create_and_upload!(io: opus_path.open, filename: 'voice.ogg', content_type: 'audio/ogg')

      expect(blob.content_type).to eq('audio/ogg')
    end

    it 'hands audio/ogg to the storage service, which is the type the object keeps' do
      types = uploaded_content_types do
        described_class.create_and_upload!(io: opus_path.open, filename: 'voice.ogg', content_type: 'audio/ogg')
      end

      expect(types).to eq(['audio/ogg'])
    end

    it 'stores a recording named .opus as audio/ogg too' do
      blob = described_class.create_and_upload!(io: opus_path.open, filename: 'voice.opus', content_type: 'audio/opus')

      expect(blob.content_type).to eq('audio/ogg')
    end

    it 'leaves an audio type it was not asked about alone' do
      blob = described_class.create_and_upload!(io: Rails.root.join('spec/assets/sample.mp3').open, filename: 'voice.mp3',
                                                content_type: 'audio/mpeg')

      expect(blob.content_type).to eq('audio/mpeg')
    end

    it 'leaves a file that is not audio alone' do
      blob = described_class.create_and_upload!(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                                                content_type: 'image/png')

      expect(blob.content_type).to eq('image/png')
    end
  end

  # The path a direct upload takes: the browser PUTs to storage and the blob is identified only
  # when it is attached. This is the one entry point the patch did cover, and it covered it with
  # an argument the method it wraps does not take.
  describe 'identification when a direct-upload blob is attached' do
    let(:blob) do
      blob = described_class.create_before_direct_upload!(
        filename: 'voice.ogg',
        byte_size: opus_path.size,
        checksum: described_class.new.send(:compute_checksum_in_chunks, opus_path.open),
        content_type: 'audio/ogg'
      )
      blob.upload_without_unfurling(opus_path.open)
      blob
    end

    it 'attaches without raising' do
      attachment = Attachment.new(file_type: :audio)

      expect { attachment.file.attach(blob.signed_id) }.not_to raise_error
    end

    it 'stores an Ogg Opus recording as audio/ogg' do
      blob.identify

      expect(blob.reload.content_type).to eq('audio/ogg')
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
