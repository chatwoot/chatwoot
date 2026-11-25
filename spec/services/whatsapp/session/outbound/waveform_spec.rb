require 'rails_helper'

RSpec.describe Whatsapp::Session::Outbound::Waveform do
  let(:samples) { described_class::SAMPLES }
  let(:ceiling) { described_class::MAX_AMPLITUDE }

  # The decoding needs a binary on the machine and the shape does not, so the shape is
  # tested on samples handed straight in. This is where the answer is actually decided:
  # everything below is about what 64 bars say about the audio.
  describe '.draw' do
    it 'always answers the fixed row of bars the contract types' do
      bars = described_class.draw(Array.new(1_000) { rand(-32_768..32_767) })

      expect(bars.length).to eq(samples)
      expect(bars).to all(be_between(0, ceiling))
    end

    # Not merely "quiet": a recording with no sound in it must not be drawn as though the
    # loudest thing in it were loud. Normalizing against its own peak would turn dithering
    # noise into a full row of bars.
    it 'draws silence as silence' do
      expect(described_class.draw(Array.new(1_000, 0))).to eq(Array.new(samples, 0))
    end

    # The acceptance shape, in the same form the issue described: tone, silence, tone. What
    # matters is that a reader can see three separate things, which is the whole reason the
    # field exists.
    it 'separates loud passages from the quiet ones between them' do
      block = ->(amplitude, count) { Array.new(count) { |i| i.even? ? amplitude : -amplitude } }
      audio = block.call(30_000, 1_000) + block.call(0, 1_000) + block.call(30_000, 1_000) +
              block.call(0, 1_000) + block.call(30_000, 1_000)

      bars = described_class.draw(audio)
      # Windows taken inside each block rather than by slicing the row into five: a bucket
      # spans about 78 samples, so the ones straddling a boundary carry both sides and say
      # nothing about either.
      average = ->(range) { bars[range].sum / bars[range].length }

      expect(average.call(2..10)).to be > 80
      expect(average.call(15..23)).to be < 20
      expect(average.call(28..36)).to be > 80
      expect(average.call(41..49)).to be < 20
      expect(average.call(55..62)).to be > 80
    end

    # The quiet half of a recording is what a curve is for. Peak alone leaves a voice as one
    # tall bar surrounded by stubs, because speech spends most of its time well under its
    # own peaks, so a passage at a tenth of the loudest has to read as more than a tenth of
    # the height.
    it 'lifts a quiet passage above its share of the peak' do
      loud = Array.new(1_000) { |i| i.even? ? 30_000 : -30_000 }
      quiet = Array.new(1_000) { |i| i.even? ? 3_000 : -3_000 }

      bars = described_class.draw(loud + quiet)
      tail = bars.last(samples / 4)

      expect(tail.sum / tail.length).to be > (ceiling / 10)
    end

    # A note shorter than the row is wide still has to fill it, because the length is what
    # the reader on the other side is typed against.
    it 'fills the row for a recording shorter than it is wide' do
      bars = described_class.draw([10_000, -10_000, 5_000])

      expect(bars.length).to eq(samples)
      expect(bars.max).to eq(ceiling)
    end

    it 'answers a row of silence for no audio at all' do
      expect(described_class.draw([])).to eq(Array.new(samples, 0))
    end
  end

  describe '.for' do
    let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
    let(:message) { create(:message, :with_attachment, account: channel.account, inbox: channel.inbox) }
    let(:attachment) { message.attachments.first }

    # Absent is "we could not measure this", and it has to stay absent. A row of zeros
    # written because a binary was missing is a measurement of nothing presented as one, and
    # the recipient's client draws it as a note with no sound in it.
    it 'answers nothing when the machine has no ffmpeg' do
      allow(described_class).to receive(:ffmpeg).and_return(nil)

      expect(described_class.for(attachment)).to be_nil
    end

    it 'answers nothing rather than raising when the file will not decode' do
      allow(described_class).to receive(:ffmpeg).and_return('/bin/false')

      expect(described_class.for(attachment)).to be_nil
    end

    # A recording somebody made with their thumb on a button is small. Past the cap the file
    # is something else carrying the voice-note flag, and reading it into this process to
    # draw 64 bars is not worth what it costs.
    it 'does not measure a file too large to be a voice note' do
      allow(attachment.file).to receive(:byte_size).and_return(described_class::MAX_MEASURED_BYTES + 1)

      expect(described_class.for(attachment)).to be_nil
    end

    it 'answers nothing for an attachment with no file' do
      expect(described_class.for(Attachment.new)).to be_nil
    end

    # The only example that runs the decoder, and the only proof that the two halves meet:
    # everything above hands samples in or stubs the binary away. It reads a file that is
    # checked in rather than one built here, so what it measures is the decoding and not
    # whether this machine's ffmpeg can also write the fixture.
    #
    # Skipped rather than stubbed where ffmpeg is missing, and it says so: a green suite
    # that quietly never decoded anything is what let `out.present?` over raw PCM ship,
    # which raises on the first byte that is not valid UTF-8 and was read as "could not
    # measure". CI installs ffmpeg for this reason.
    it 'measures a real recording end to end', if: described_class.send(:ffmpeg).present? do
      # Built as its own row rather than by replacing what the factory attached. `attach` on
      # a persisted record saves without a bang, so a refused save is silent and the old
      # blob stays: this example spent a CI round decoding a 27 KB PNG and reporting that
      # the output had no stream.
      record = message.attachments.new(account_id: message.account_id, file_type: :audio,
                                       meta: { 'is_voice_message' => true })
      record.file.attach(io: Rails.root.join('spec/assets/sample.ogg').open, filename: 'nota.ogg',
                         content_type: 'audio/ogg')
      record.save!

      bars = described_class.for(record.reload)

      expect(bars).to be_present, "waveform nil para um blob de #{record.file.byte_size} bytes"
      expect(bars.length).to eq(samples)
      expect(bars).to all(be_between(0, ceiling))
      # Normalized against its own peak, so a recording with sound in it always reaches the
      # top somewhere. A row that never does is silence, which this file is not.
      expect(bars.max).to eq(ceiling)
      expect(bars.count(&:zero?)).to be < samples
    end
  end
end
