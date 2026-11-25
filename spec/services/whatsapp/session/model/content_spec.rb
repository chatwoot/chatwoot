require 'rails_helper'

RSpec.describe Whatsapp::Session::Model::Content do
  it 'builds the right class from the payload type' do
    expect(described_class.from_h({ 'type' => 'text', 'body' => 'oi' })).to be_a(described_class::Text)
    expect(described_class.from_h({ 'type' => 'location', 'latitude' => 1.0, 'longitude' => 2.0 }))
      .to be_a(described_class::Location)
  end

  it 'keeps the type inside the payload so a message round-trips' do
    content = described_class::Text.new(body: 'oi')

    expect(content.to_h).to eq({ 'body' => 'oi', 'type' => 'text' })
  end

  it 'refuses an unknown content type' do
    expect { described_class.from_h({ 'type' => 'hologram' }) }.to raise_error(Whatsapp::Session::Errors::InvalidPayload)
  end

  describe described_class::Media do
    it 'maps the whatsapp media kind to the chatwoot attachment type' do
      expect(described_class.new(kind: 'sticker').attachment_file_type).to eq(:image)
      expect(described_class.new(kind: 'audio', voice_note: true).attachment_file_type).to eq(:audio)
      expect(described_class.new(kind: 'document').attachment_file_type).to eq(:file)
    end

    it 'refuses an unknown media kind' do
      expect { described_class.new(kind: 'hologram') }.to raise_error(Whatsapp::Session::Errors::InvalidPayload)
    end

    it 'carries the picture size and the waveform to the wire' do
      media = described_class.new(kind: 'audio', voice_note: true, waveform: Array.new(64, 50))

      expect(media.to_h).to include('waveform' => Array.new(64, 50))
      expect(described_class.new(kind: 'video', width: 1920, height: 1080).to_h)
        .to include('width' => 1920, 'height' => 1080)
    end

    # The connector refuses these too, and refusing here as well is what keeps the sender
    # from finding out after the file has already been uploaded.
    it 'refuses a waveform that is not a row of 64 amplitudes' do
      [Array.new(30, 10), Array.new(64, 250), Array.new(64, -1), Array.new(64, 'alto')].each do |waveform|
        expect { described_class.new(kind: 'audio', waveform: waveform) }
          .to raise_error(Whatsapp::Session::Errors::InvalidPayload)
      end
    end

    it 'takes no waveform at all without complaint' do
      expect { described_class.new(kind: 'audio', waveform: nil) }.not_to raise_error
    end
  end

  describe described_class::Reaction do
    it 'treats an empty emoji as a removal' do
      expect(described_class.new(target_id: '3EB0', emoji: '')).to be_removal
      expect(described_class.new(target_id: '3EB0', emoji: '👍')).not_to be_removal
    end
  end
end
