require 'rails_helper'

RSpec.describe Audio::TranscoderService do
  let(:voice) { Rails.root.join('spec/assets/sample_voice.oga').open('rb') }
  let(:vorbis) { Rails.root.join('spec/assets/sample.ogg').open('rb') }
  let(:mp3) { Rails.root.join('spec/assets/sample.mp3').open('rb') }

  after { [voice, vorbis, mp3].each { |file| file.close unless file.closed? } }

  describe '#perform' do
    context 'when ffmpeg is installed' do
      before { skip 'ffmpeg is not installed' unless described_class.ffmpeg_available? }

      it 'transcodes a WhatsApp Ogg/Opus voice note to mp3' do
        result = described_class.new(io: voice, filename: 'voice.oga', content_type: 'audio/ogg; codecs=opus').perform

        expect(result).to include(transcoded: true, filename: 'voice.mp3', content_type: 'audio/mpeg')
        expect(Marcel::MimeType.for(result[:io])).to eq('audio/mpeg')
      end

      it 'transcodes Ogg/Vorbis to mp3' do
        result = described_class.new(io: vorbis, filename: 'clip.ogg', content_type: 'audio/ogg').perform

        expect(result).to include(transcoded: true, filename: 'clip.mp3')
      end

      it 'detects Ogg by extension when the content type is missing' do
        result = described_class.new(io: voice, filename: 'voice.oga', content_type: nil).perform

        expect(result[:transcoded]).to be(true)
      end

      it 'names the output audio.mp3 when there is no filename' do
        result = described_class.new(io: voice, filename: nil, content_type: 'audio/ogg').perform

        expect(result[:filename]).to eq('audio.mp3')
      end

      it 'leaves no temporary files behind' do
        before_files = Dir.glob(File.join(Dir.tmpdir, 'cw-audio*'))
        described_class.new(io: voice, filename: 'voice.oga', content_type: 'audio/ogg').perform

        expect(Dir.glob(File.join(Dir.tmpdir, 'cw-audio*'))).to match_array(before_files)
      end
    end

    it 'passes mp3 through untouched' do
      result = described_class.new(io: mp3, filename: 'voice.mp3', content_type: 'audio/mpeg').perform

      expect(result).to eq({ transcoded: false })
    end

    it 'does nothing when ffmpeg is missing' do
      allow(described_class).to receive(:ffmpeg_available?).and_return(false)

      result = described_class.new(io: voice, filename: 'voice.oga', content_type: 'audio/ogg').perform

      expect(result).to eq({ transcoded: false })
    end

    context 'when ffmpeg fails' do
      let(:tracker) { instance_double(ChatwootExceptionTracker, capture_exception: true) }

      before do
        allow(described_class).to receive(:ffmpeg_available?).and_return(true)
        allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)
      end

      it 'reports the error and leaves the source readable from the start' do
        allow(Open3).to receive(:popen3).and_raise(Errno::ENOENT, 'ffmpeg')

        result = described_class.new(io: voice, filename: 'voice.oga', content_type: 'audio/ogg').perform

        expect(result).to eq({ transcoded: false })
        expect(tracker).to have_received(:capture_exception)
        expect(voice.read.bytesize).to eq(File.size(voice.path))
      end

      context 'with the real ffmpeg binary' do
        before { skip 'ffmpeg is not installed' unless system('ffmpeg', '-version', out: File::NULL, err: File::NULL) }

        it 'keeps the original when the bytes are not audio' do
          garbage = StringIO.new('this is not an ogg file')

          result = described_class.new(io: garbage, filename: 'voice.oga', content_type: 'audio/ogg').perform

          expect(result).to eq({ transcoded: false })
          expect(tracker).to have_received(:capture_exception)
          expect(garbage.read).to eq('this is not an ogg file')
        end

        it 'refuses a playlist disguised as ogg' do
          playlist = StringIO.new("#EXTM3U\n#EXT-X-MEDIA-SEQUENCE:0\n#EXTINF:1.0,\nfile:///etc/passwd\n#EXT-X-ENDLIST\n")

          result = described_class.new(io: playlist, filename: 'voice.oga', content_type: 'audio/ogg').perform

          expect(result).to eq({ transcoded: false })
        end

        it 'kills ffmpeg when it runs past the timeout' do
          stub_const("#{described_class}::TIMEOUT_SECONDS", 0)
          allow(Process).to receive(:kill).and_call_original

          result = described_class.new(io: voice, filename: 'voice.oga', content_type: 'audio/ogg').perform

          expect(result).to eq({ transcoded: false })
          expect(Process).to have_received(:kill).with('KILL', kind_of(Integer))
        end
      end
    end
  end
end
