require 'rails_helper'

RSpec.describe Whatsapp::Session::Outbound::AttachmentAdapter do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:message) { create(:message, :with_attachment, account: channel.account, inbox: channel.inbox) }
  let(:attachment) { message.attachments.first }

  it 'describes the file in the terms the protocol uses' do
    media = described_class.new(attachment, caption: 'segue a foto', channel: channel).perform

    expect(media.kind).to eq('image')
    expect(media.caption).to eq('segue a foto')
    expect(media.ref.url).to be_present
  end

  # `download_url` rewrites the blob of an `.ogg` recorded as `audio/opus`, which is the
  # shape the fork's own transcode pipeline produces. Reading the type before that runs
  # leaves the media and its ref advertising different ones, and the type is what decides
  # whether WhatsApp plays it as a voice note.
  it 'advertises one MIME type for a voice note whose blob is normalized on the way out' do
    attachment.file.blob.update!(content_type: 'audio/opus', filename: 'gravacao.ogg')
    attachment.update!(file_type: :audio, meta: { 'is_voice_message' => true })

    media = described_class.new(attachment.reload, channel: channel).perform

    expect(media.mime).to eq('audio/ogg')
    expect(media.ref.mime).to eq(media.mime)
    expect(media.voice_note).to be(true)
  end

  # The flag the connector turns into a PtvMessage. Absent rather than false when it does not
  # apply, which is how the contract carries it.
  describe 'a video note' do
    def sent(file_type:, content_type:, meta:)
      attachment.file.blob.update!(content_type: content_type)
      attachment.update!(file_type: file_type, meta: meta)
      described_class.new(attachment.reload, channel: channel).perform
    end

    it 'asks the connector for a video note when the video is tagged as one' do
      media = sent(file_type: :video, content_type: 'video/mp4', meta: { 'is_video_note' => true })

      expect(media.kind).to eq('video')
      expect(media.video_note).to be(true)
      expect(media.to_h).to include('video_note' => true)
    end

    it 'sends an untagged video as an ordinary one' do
      media = sent(file_type: :video, content_type: 'video/mp4', meta: {})

      expect(media.to_h).not_to have_key('video_note')
    end

    it 'sends a video whose tag is false as an ordinary one' do
      media = sent(file_type: :video, content_type: 'video/mp4', meta: { 'is_video_note' => false })

      expect(media.to_h).not_to have_key('video_note')
    end

    # The connector refuses the flag on anything but a video, so carrying it would turn a
    # picture that sends today into a refusal.
    it 'never asks for one on a picture' do
      media = sent(file_type: :image, content_type: 'image/png', meta: { 'is_video_note' => true })

      expect(media.to_h).not_to have_key('video_note')
    end
  end

  # What the recipient's client lays the bubble out from before a byte has arrived. All of
  # it read from what ActiveStorage already analysed, except the waveform, which no analyser
  # produces.
  describe 'the measurements the bubble is drawn from' do
    def analysed(metadata)
      attachment.file.blob.update!(metadata: attachment.file.blob.metadata.merge(metadata))
      described_class.new(attachment.reload, channel: channel).perform
    end

    it 'carries both sides of a picture it has a size for' do
      media = analysed('width' => 1280, 'height' => 720)

      expect(media.width).to eq(1280)
      expect(media.height).to eq(720)
    end

    # The connector refuses one side without the other, and it is right to: half a size
    # lays out nothing, and the two only ever come from the same analysis anyway.
    it 'sends neither side when it only has one' do
      media = analysed('width' => 1280, 'height' => nil)

      expect(media.width).to be_nil
      expect(media.height).to be_nil
    end

    # The case this has to get right on a machine with no ffprobe, which is most developer
    # machines: ActiveStorage stores the analysis with the sizes null. Absent has to stay
    # absent, because a zero on the wire is a measurement of nothing and the client draws a
    # bubble from it.
    it 'sends no size at all when nothing analysed the file' do
      media = described_class.new(attachment, channel: channel).perform

      expect(media.to_h).not_to have_key(:width)
      expect(media.to_h).not_to have_key(:height)
    end

    it 'sends no duration for a picture, which has none' do
      media = analysed('width' => 1280, 'height' => 720, 'duration' => 12.0)

      expect(media.duration).to be_nil
    end

    context 'with a video' do
      before { attachment.update!(file_type: :video) }

      it 'carries the size and the duration, rounded to the seconds the contract types' do
        media = analysed('width' => 640, 'height' => 360, 'duration' => 8.4)

        expect([media.width, media.height, media.duration]).to eq([640, 360, 8])
      end
    end

    context 'with a voice note' do
      before do
        attachment.file.blob.update!(content_type: 'audio/ogg', filename: 'gravacao.ogg')
        attachment.update!(file_type: :audio, meta: { 'is_voice_message' => true })
      end

      it 'carries the shape of the audio and no picture size' do
        allow(Whatsapp::Session::Outbound::Waveform).to receive(:for).and_return(Array.new(64, 42))

        media = analysed('duration' => 7.2)

        expect(media.waveform.length).to eq(64)
        expect(media.duration).to eq(7)
        expect(media.to_h).not_to have_key(:width)
      end

      # A note the machine could not measure travels without the field rather than with a
      # flat row, which is a shape that is not the audio.
      it 'leaves the field out when the audio could not be measured' do
        allow(Whatsapp::Session::Outbound::Waveform).to receive(:for).and_return(nil)

        expect(described_class.new(attachment.reload, channel: channel).perform.to_h).not_to have_key(:waveform)
      end
    end

    # Played from a track, not from a row of bars, so measuring it would cost the decode
    # and change nothing on screen.
    it 'does not measure an audio file nobody recorded as a note' do
      attachment.file.blob.update!(content_type: 'audio/mpeg', filename: 'musica.mp3')
      attachment.update!(file_type: :audio, meta: {})
      allow(Whatsapp::Session::Outbound::Waveform).to receive(:for)

      described_class.new(attachment.reload, channel: channel).perform

      expect(Whatsapp::Session::Outbound::Waveform).not_to have_received(:for)
    end

    it 'sends nothing measured for a document' do
      attachment.file.blob.update!(content_type: 'application/pdf', filename: 'contrato.pdf')
      attachment.update!(file_type: :file)

      media = analysed('width' => 600, 'height' => 800, 'duration' => 3.0)

      expect(media.to_h.keys).not_to include(:width, :height, :duration, :waveform)
    end
  end

  describe 'the address the provider is told to fetch from' do
    let(:disk_url) { 'http://localhost:3000/rails/active_storage/disk/TOKEN/avatar.png' }

    before { allow(attachment).to receive(:download_url).and_return(disk_url) }

    it 'is the public one until the inbox says the provider cannot reach it' do
      expect(described_class.new(attachment, channel: channel).media_url).to eq(disk_url)
    end

    it 'moves to the internal host for a provider sitting on a private network' do
      with_modified_env INTERNAL_HOST_URL: 'http://rails:3000' do
        expect(described_class.new(attachment, channel: channel).media_url)
          .to eq('http://rails:3000/rails/active_storage/disk/TOKEN/avatar.png')
      end
    end

    # INTERNAL_HOST_URL is one address for the whole deployment, and a hosted provider is
    # on the far side of the network it points into. An installation running a connector
    # next to a hosted inbox would otherwise hand that inbox a host it cannot resolve, and
    # every attachment it sent would fail with nothing pointing at the setting.
    it 'leaves a hosted provider on the public host even where an internal one is set' do
      hosted = create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false)

      with_modified_env INTERNAL_HOST_URL: 'http://rails:3000' do
        expect(described_class.new(attachment, channel: hosted).media_url).to eq(disk_url)
      end
    end

    # With S3, GCS or any other cloud service the blob answers a presigned URL of its
    # own. Its path is not one Rails serves and its signature is bound to the host it was
    # made for, so moving it to the internal host is a 404 on every attachment the inbox
    # ever sends: the storage is reachable over the internet anyway.
    it 'leaves a presigned cloud-storage URL where it is' do
      url = 'https://bucket.s3.sa-east-1.amazonaws.com/xg7/avatar.png?X-Amz-Signature=deadbeef'
      allow(attachment).to receive(:download_url).and_return(url)

      with_modified_env INTERNAL_HOST_URL: 'http://rails:3000' do
        expect(described_class.new(attachment, channel: channel).media_url).to eq(url)
      end
    end
  end
end
