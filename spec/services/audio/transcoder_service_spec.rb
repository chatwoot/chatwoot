require 'rails_helper'

RSpec.describe Audio::TranscoderService do
  let(:ogg) { Rails.root.join('spec/assets/sample.ogg').open }
  let(:mp3) { Rails.root.join('spec/assets/sample.mp3').open }

  describe '#perform' do
    context 'when given an OGG audio file' do
      it 'transcodes it to mp3' do
        result = described_class.new(io: ogg, filename: 'voice.ogg', content_type: 'audio/ogg').perform

        expect(result[:transcoded]).to be(true)
        expect(result[:content_type]).to eq('audio/mpeg')
        expect(result[:filename]).to eq('voice.mp3')
        expect(result[:io].size).to be > 0
      end

      it 'leaves no temporary files behind in tmpdir' do
        before_files = Dir.glob(File.join(Dir.tmpdir, 'cw-audio-*'))
        described_class.new(io: ogg, filename: 'voice.ogg', content_type: 'audio/ogg').perform
        after_files = Dir.glob(File.join(Dir.tmpdir, 'cw-audio-*'))

        expect(after_files).to match_array(before_files)
      end
    end

    context 'when content_type is missing but the filename is an audio extension' do
      it 'detects by extension and transcodes' do
        result = described_class.new(io: ogg, filename: 'voice.oga', content_type: nil).perform

        expect(result[:transcoded]).to be(true)
        expect(result[:content_type]).to eq('audio/mpeg')
      end
    end

    context 'when the file is already mp3' do
      it 'passes through untouched' do
        result = described_class.new(io: mp3, filename: 'voice.mp3', content_type: 'audio/mpeg').perform

        expect(result).to eq({ transcoded: false })
      end
    end

    context 'when ffmpeg is not available' do
      it 'passes through and does not raise' do
        service = described_class.new(io: ogg, filename: 'voice.ogg', content_type: 'audio/ogg')
        allow(service).to receive(:system).and_return(false)

        expect(service.perform).to eq({ transcoded: false })
      end
    end

    context 'when ffmpeg fails' do
      it 'reports the error and keeps the original' do
        movie = instance_double(FFMPEG::Movie)
        allow(FFMPEG::Movie).to receive(:new).and_return(movie)
        allow(movie).to receive(:transcode).and_raise(StandardError, 'boom')
        tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)

        result = described_class.new(io: ogg, filename: 'voice.ogg', content_type: 'audio/ogg').perform

        expect(result).to eq({ transcoded: false })
        expect(tracker).to have_received(:capture_exception)
        # the source io is left rewound so the kept-original attachment isn't an empty stream
        expect(ogg.read).not_to be_empty
      end
    end
  end
end
