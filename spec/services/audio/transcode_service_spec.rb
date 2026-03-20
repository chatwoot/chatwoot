require 'rails_helper'

RSpec.describe Audio::TranscodeService do
  let(:message) { create(:message) }
  let(:attachment) do
    attachment = message.attachments.new(account_id: message.account_id, file_type: :audio)
    attachment.file.attach(io: Rails.root.join('spec/assets/sample.mp3').open, filename: 'sample.mp3', content_type: 'audio/mpeg')
    attachment.save!
    attachment
  end

  describe '#perform' do
    context 'with unsupported format' do
      it 'raises UnsupportedFormatError' do
        error = nil
        begin
          described_class.new(attachment, 'aac').perform
        rescue StandardError => e
          error = e
        end

        expect(error).not_to be_nil
        expect(error.class.name).to eq('CustomExceptions::Audio::UnsupportedFormatError')
        expect(error.message).to match(/Unsupported transcode format: aac/)
      end
    end

    context 'with opus format' do
      it 'skips transcoding when file is already in target format' do
        ogg_attachment = message.attachments.new(account_id: message.account_id, file_type: :audio)
        ogg_attachment.file.attach(io: StringIO.new('ogg_data'), filename: 'recording.ogg', content_type: 'audio/ogg')
        ogg_attachment.save!

        allow(FFMPEG::Movie).to receive(:new)

        described_class.new(ogg_attachment, 'opus').perform

        expect(FFMPEG::Movie).not_to have_received(:new)
        expect(ogg_attachment.file.content_type).to eq('audio/ogg')
      end

      it 'transcodes audio to ogg/opus format' do
        mock_movie = instance_double(FFMPEG::Movie, valid?: true)
        allow(FFMPEG::Movie).to receive(:new).and_return(mock_movie)
        allow(mock_movie).to receive(:transcode) do |output_path, _options|
          File.write(output_path, 'fake_opus_data')
        end

        described_class.new(attachment, 'opus').perform

        expect(attachment.file.filename.to_s).to eq('sample.ogg')
        expect(attachment.file.content_type).to eq('audio/ogg')
        expect(attachment.file_type).to eq('audio')
      end

      it 'transcodes using source_file when provided' do
        uploaded_file = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/sample.mp3').to_s, 'audio/mpeg')

        mock_movie = instance_double(FFMPEG::Movie, valid?: true)
        allow(FFMPEG::Movie).to receive(:new).and_return(mock_movie)
        allow(mock_movie).to receive(:transcode) do |output_path, _options|
          File.write(output_path, 'fake_opus_data')
        end

        described_class.new(attachment, 'opus', source_file: uploaded_file).perform

        expect(attachment.file.filename.to_s).to eq('sample.ogg')
        expect(attachment.file.content_type).to eq('audio/ogg')
        expect(attachment.file_type).to eq('audio')
      end

      it 'raises TranscodingError when the audio file is invalid' do
        mock_movie = instance_double(FFMPEG::Movie, valid?: false)
        allow(FFMPEG::Movie).to receive(:new).and_return(mock_movie)

        error = nil
        begin
          described_class.new(attachment, 'opus').perform
        rescue StandardError => e
          error = e
        end

        expect(error).not_to be_nil
        expect(error.class.name).to eq('CustomExceptions::Audio::TranscodingError')
        expect(error.message).to match(/Invalid or unreadable audio file/)
      end

      it 'raises TranscodingError when FFmpeg fails' do
        mock_movie = instance_double(FFMPEG::Movie, valid?: true)
        allow(FFMPEG::Movie).to receive(:new).and_return(mock_movie)
        allow(mock_movie).to receive(:transcode).and_raise(FFMPEG::Error, 'encoding failed')

        error = nil
        begin
          described_class.new(attachment, 'opus').perform
        rescue StandardError => e
          error = e
        end

        expect(error).not_to be_nil
        expect(error.class.name).to eq('CustomExceptions::Audio::TranscodingError')
        expect(error.message).to match(/FFmpeg transcoding failed/)
      end
    end
  end
end
