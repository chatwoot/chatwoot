require 'rails_helper'

describe Instagram::AudioConversionService do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, contact: contact, inbox: inbox, account: account) }
  let(:message) { create(:message, conversation: conversation, account: account) }

  let(:service) { described_class.new }

  describe '.convert_to_instagram_format' do
    it 'delegates to instance method' do
      attachment = double('attachment')
      expect_any_instance_of(described_class).to receive(:convert_to_instagram_format).with(attachment)
      described_class.convert_to_instagram_format(attachment)
    end
  end

  describe '#convert_to_instagram_format' do
    context 'when attachment does not need conversion' do
      let(:attachment) do
        attachment = message.attachments.build(account_id: account.id, file_type: :audio)
        attachment.file.attach(
          io: StringIO.new('audio content'),
          filename: 'test.m4a',
          content_type: 'audio/mp4'
        )
        attachment.save!
        attachment
      end

      it 'returns original URL without conversion' do
        allow(service).to receive(:should_convert_audio?).and_return(false)
        allow(service).to receive(:build_public_url).and_return('http://example.com/original.m4a')

        result = service.convert_to_instagram_format(attachment)

        expect(result).to eq('http://example.com/original.m4a')
        expect(service).to have_received(:should_convert_audio?).with(attachment)
        expect(service).to have_received(:build_public_url).with(attachment)
      end
    end

    context 'when attachment needs conversion' do
      let(:attachment) do
        attachment = message.attachments.build(account_id: account.id, file_type: :audio)
        attachment.file.attach(
          io: StringIO.new('audio content'),
          filename: 'test.mp3',
          content_type: 'audio/mpeg'
        )
        attachment.save!
        attachment
      end

      before do
        allow(service).to receive(:should_convert_audio?).and_return(true)
        allow(service).to receive(:download_attachment).and_return(double('temp_file'))
        allow(service).to receive(:convert_file_to_mp4).and_return(double('converted_file'))
        allow(service).to receive(:upload_converted_file).and_return('http://example.com/converted.m4a')
        allow(service).to receive(:cleanup_temp_files)
      end

      it 'converts audio and returns new URL' do
        result = service.convert_to_instagram_format(attachment)

        expect(result).to eq('http://example.com/converted.m4a')
        expect(service).to have_received(:download_attachment).with(attachment)
        expect(service).to have_received(:convert_file_to_mp4)
        expect(service).to have_received(:upload_converted_file)
        expect(service).to have_received(:cleanup_temp_files)
      end

      it 'falls back to original URL on conversion error' do
        allow(service).to receive(:download_attachment).and_raise(StandardError.new('Conversion failed'))
        allow(service).to receive(:build_public_url).and_return('http://example.com/original.mp3')

        result = service.convert_to_instagram_format(attachment)

        expect(result).to eq('http://example.com/original.mp3')
        expect(service).to have_received(:build_public_url).with(attachment)
      end
    end
  end

  describe '#should_convert_audio?' do
    context 'when attachment is not audio' do
      let(:attachment) do
        attachment = message.attachments.build(account_id: account.id, file_type: :image)
        attachment.file.attach(
          io: StringIO.new('image content'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
        attachment.save!
        attachment
      end

      it 'returns false' do
        expect(service.send(:should_convert_audio?, attachment)).to be false
      end
    end

    context 'when attachment is audio' do
      let(:attachment) do
        attachment = message.attachments.build(account_id: account.id, file_type: :audio)
        attachment.file.attach(
          io: StringIO.new('audio content'),
          filename: filename,
          content_type: content_type
        )
        attachment.save!
        attachment
      end

      context 'with Instagram-compatible format' do
        let(:filename) { 'test.m4a' }
        let(:content_type) { 'audio/mp4' }

        it 'returns false' do
          expect(service.send(:should_convert_audio?, attachment)).to be false
        end
      end

      context 'with format that needs conversion' do
        let(:filename) { 'test.mp3' }
        let(:content_type) { 'audio/mpeg' }

        it 'returns true' do
          expect(service.send(:should_convert_audio?, attachment)).to be true
        end
      end

      context 'with OGG format' do
        let(:filename) { 'test.ogg' }
        let(:content_type) { 'audio/ogg' }

        it 'returns true' do
          expect(service.send(:should_convert_audio?, attachment)).to be true
        end
      end

      context 'with Opus format' do
        let(:filename) { 'test.opus' }
        let(:content_type) { 'audio/opus' }

        it 'returns true' do
          expect(service.send(:should_convert_audio?, attachment)).to be true
        end
      end

      context 'when file exceeds size limit' do
        let(:filename) { 'test.mp3' }
        let(:content_type) { 'audio/mpeg' }

        before do
          allow(attachment.file).to receive(:byte_size).and_return(26.megabytes)
        end

        it 'returns false and logs warning' do
          expect(Rails.logger).to receive(:warn).with(/Audio file size.*exceeds Instagram limit/)
          expect(service.send(:should_convert_audio?, attachment)).to be false
        end
      end
    end

    context 'when attachment file is not attached' do
      let(:attachment) { message.attachments.build(account_id: account.id, file_type: :audio) }

      it 'returns false' do
        expect(service.send(:should_convert_audio?, attachment)).to be false
      end
    end
  end

  describe '#download_attachment' do
    let(:attachment) do
      attachment = message.attachments.build(account_id: account.id, file_type: :audio)
      attachment.file.attach(
        io: StringIO.new('audio content'),
        filename: 'test.mp3',
        content_type: 'audio/mpeg'
      )
      attachment.save!
      attachment
    end

    it 'downloads attachment to temporary file' do
      allow(attachment.file).to receive(:download).and_yield('chunk1').and_yield('chunk2')

      temp_file = service.send(:download_attachment, attachment)

      expect(temp_file).to be_a(Tempfile)
      temp_file.rewind
      content = temp_file.read
      expect(content).to eq('chunk1chunk2')

      temp_file.close
      temp_file.unlink
    end
  end

  describe '#convert_file_to_mp4' do
    let(:input_file) { Tempfile.new(['test_input', '.mp3']) }

    before do
      input_file.write('dummy audio content')
      input_file.rewind
    end

    after do
      input_file.close
      input_file.unlink
    end

    context 'when FFmpeg is available' do
      before do
        allow(service).to receive(:verify_ffmpeg_availability)
        allow(service).to receive(:system).and_return(true)
        allow(File).to receive(:size?).and_return(1024)
        allow(File).to receive(:size).and_return(1024)
      end

      it 'converts file to MP4 format' do
        output_file = service.send(:convert_file_to_mp4, input_file)

        expect(output_file).to be_a(Tempfile)
        expect(service).to have_received(:verify_ffmpeg_availability)
        expect(service).to have_received(:system).with(
          'ffmpeg', '-i', input_file.path,
          '-c:a', 'aac',
          '-b:a', '128k',
          '-ar', '44100',
          '-ac', '2',
          '-movflags', '+faststart',
          '-f', 'mp4',
          '-vn',
          '-y', output_file.path,
          out: File::NULL,
          err: File::NULL
        )

        output_file.close
        output_file.unlink
      end

      it 'raises error when FFmpeg conversion fails' do
        allow(service).to receive(:system).and_return(false)

        expect { service.send(:convert_file_to_mp4, input_file) }
          .to raise_error(/FFmpeg conversion failed/)
      end

      it 'raises error when output file exceeds size limit' do
        allow(File).to receive(:size).and_return(26.megabytes)

        expect { service.send(:convert_file_to_mp4, input_file) }
          .to raise_error(/Converted file size.*exceeds Instagram limit/)
      end
    end

    context 'when FFmpeg is not available' do
      before do
        allow(service).to receive(:verify_ffmpeg_availability).and_raise('FFmpeg is not installed')
      end

      it 'raises error about FFmpeg availability' do
        expect { service.send(:convert_file_to_mp4, input_file) }
          .to raise_error('FFmpeg is not installed')
      end
    end
  end

  describe '#upload_converted_file' do
    let(:attachment) do
      attachment = message.attachments.build(account_id: account.id, file_type: :audio)
      attachment.file.attach(
        io: StringIO.new('audio content'),
        filename: 'test.mp3',
        content_type: 'audio/mpeg'
      )
      attachment.save!
      attachment
    end

    let(:mp4_file) { Tempfile.new(['converted', '.m4a']) }

    before do
      mp4_file.write('converted audio content')
      mp4_file.rewind
    end

    after do
      mp4_file.close
      mp4_file.unlink
    end

    it 'creates new blob and updates attachment' do
      original_blob = attachment.file.blob
      allow(service).to receive(:build_public_url_for_blob).and_return('http://example.com/converted.m4a')

      result = service.send(:upload_converted_file, attachment, mp4_file)

      expect(result).to eq('http://example.com/converted.m4a')
      expect(attachment.file.filename.to_s).to eq('test.m4a')
      expect(attachment.file.content_type).to eq('audio/mp4')
      expect(attachment.file.blob).not_to eq(original_blob)
    end
  end

  describe '#build_public_url' do
    let(:attachment) do
      attachment = message.attachments.build(account_id: account.id, file_type: :audio)
      attachment.file.attach(
        io: StringIO.new('audio content'),
        filename: 'test.m4a',
        content_type: 'audio/mp4'
      )
      attachment.save!
      attachment
    end

    it 'builds public URL for attachment' do
      allow(service).to receive(:build_public_url_for_blob).and_return('http://example.com/test.m4a')

      result = service.send(:build_public_url, attachment)

      expect(result).to eq('http://example.com/test.m4a')
      expect(service).to have_received(:build_public_url_for_blob).with(attachment.file)
    end
  end

  describe '#build_public_url_for_blob' do
    let(:blob) { double('blob') }

    it 'builds rails blob URL with configured host' do
      allow(ENV).to receive(:fetch).with('FRONTEND_URL', anything).and_return('https://chatwoot.example.com')
      allow(ENV).to receive(:fetch).with('PORT', 3000).and_return(3000)
      allow(service).to receive(:rails_blob_url).and_return('https://chatwoot.example.com/rails/active_storage/blobs/xyz')

      result = service.send(:build_public_url_for_blob, blob)

      expect(result).to eq('https://chatwoot.example.com/rails/active_storage/blobs/xyz')
      expect(service).to have_received(:rails_blob_url).with(blob, host: 'https://chatwoot.example.com')
    end

    it 'uses default localhost when FRONTEND_URL not set' do
      allow(ENV).to receive(:fetch).with('FRONTEND_URL', anything).and_return('http://localhost:3000')
      allow(ENV).to receive(:fetch).with('PORT', 3000).and_return(3000)
      allow(service).to receive(:rails_blob_url).and_return('http://localhost:3000/rails/active_storage/blobs/xyz')

      result = service.send(:build_public_url_for_blob, blob)

      expect(result).to eq('http://localhost:3000/rails/active_storage/blobs/xyz')
    end
  end

  describe '#verify_ffmpeg_availability' do
    context 'when FFmpeg is available' do
      before do
        allow(service).to receive(:system).with('which ffmpeg > /dev/null 2>&1').and_return(true)
      end

      it 'does not raise error' do
        expect { service.send(:verify_ffmpeg_availability) }.not_to raise_error
      end
    end

    context 'when FFmpeg is not available' do
      before do
        allow(service).to receive(:system).with('which ffmpeg > /dev/null 2>&1').and_return(false)
      end

      it 'raises error' do
        expect { service.send(:verify_ffmpeg_availability) }
          .to raise_error('FFmpeg is not installed. Please install FFmpeg to enable audio conversion for Instagram compatibility.')
      end
    end
  end

  describe '#cleanup_temp_files' do
    let(:temp_file1) { double('temp_file1', close: nil, unlink: nil) }
    let(:temp_file2) { double('temp_file2', close: nil, unlink: nil) }
    let(:invalid_file) { 'not_a_file' }

    it 'cleans up valid temporary files' do
      allow(temp_file1).to receive(:respond_to?).with(:close).and_return(true)
      allow(temp_file1).to receive(:respond_to?).with(:unlink).and_return(true)
      allow(temp_file2).to receive(:respond_to?).with(:close).and_return(true)
      allow(temp_file2).to receive(:respond_to?).with(:unlink).and_return(true)

      service.send(:cleanup_temp_files, [temp_file1, temp_file2, nil])

      expect(temp_file1).to have_received(:close)
      expect(temp_file1).to have_received(:unlink)
      expect(temp_file2).to have_received(:close)
      expect(temp_file2).to have_received(:unlink)
    end

    it 'handles cleanup errors gracefully' do
      allow(temp_file1).to receive(:respond_to?).with(:close).and_return(true)
      allow(temp_file1).to receive(:close).and_raise(StandardError.new('Cleanup failed'))
      expect(Rails.logger).to receive(:warn).with(/Failed to cleanup temp file/)

      expect { service.send(:cleanup_temp_files, [temp_file1]) }.not_to raise_error
    end

    it 'skips invalid files' do
      expect { service.send(:cleanup_temp_files, [invalid_file]) }.not_to raise_error
    end
  end

  describe 'constants' do
    it 'defines Instagram audio formats' do
      expect(described_class::INSTAGRAM_AUDIO_FORMATS).to include(
        'aac' => 'audio/aac',
        'm4a' => 'audio/mp4',
        'mp4' => 'audio/mp4',
        'wav' => 'audio/wav'
      )
    end

    it 'defines maximum file size' do
      expect(described_class::MAX_FILE_SIZE).to eq(25.megabytes)
    end
  end
end