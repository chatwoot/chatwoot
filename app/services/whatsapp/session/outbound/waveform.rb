# The row of bars a voice note's bubble draws: exactly 64 amplitudes, 0 to 100.
#
# WhatsApp's own clients draw this from the audio, so a note sent without it arrives with a
# flat bar where every other note in the conversation has a shape. The connector carries the
# field and fills nothing in: the caller is the side holding the file.
#
# Filling it with a constant was considered and rejected upstream, for the reason that
# applies here too: a shape that is not the audio is worse than an honest empty bar.
class Whatsapp::Session::Outbound::Waveform
  media = Whatsapp::Session::Model::Content::Media
  SAMPLES = media::WAVEFORM_SAMPLES
  MAX_AMPLITUDE = media::MAX_AMPLITUDE

  # Mono, 8 kHz, signed 16-bit. The rate is far below anything worth listening to and far
  # above what 64 buckets can show: a minute of audio still lands ~7500 samples in each
  # bucket, and the peak of 7500 is the same peak whether they were sampled at 8 kHz or 48.
  DECODE_RATE = 8_000
  DECODE_FORMAT = %w[-f s16le -ac 1].freeze

  # Peak per bucket, not RMS. RMS flattens speech into an almost straight line, because a
  # voice spends most of its time well below its own peaks; the bars a phone draws track
  # the peaks. The curve then lifts the quiet buckets so the shape reads at a glance
  # instead of being one tall bar surrounded by stubs.
  CURVE = 0.7

  # A voice note is a recording somebody made with their thumb on a button, so it is small
  # by construction. This is not a limit on what can be sent, only on what is measured:
  # past it the file is something else that happens to be flagged as a voice note, and
  # reading it into this process to draw 64 bars is not worth what it costs.
  MAX_MEASURED_BYTES = 10.megabytes

  class << self
    # The waveform for an attachment, or nil when it cannot be measured. Nil is the honest
    # answer for every failure here -- no ffmpeg, a file that will not decode, silence that
    # is not silence -- because the field is optional on the wire and an absent one is what
    # every client already handles.
    def for(attachment)
      return unless measurable?(attachment)

      samples = decode(attachment)
      return if samples.blank?

      draw(samples)
    rescue StandardError => e
      Rails.logger.warn("[WHATSAPP] could not measure the waveform of attachment #{attachment&.id}: #{e.class}: #{e.message}")
      nil
    end

    # Amplitudes into the fixed row of bars. Pure, and separated from the decoding on
    # purpose: this is where the shape is decided, and it is the half that can be measured
    # without a binary on the machine running the tests.
    def draw(samples)
      buckets = bucket(samples)
      loudest = buckets.max
      return Array.new(SAMPLES, 0) if loudest.nil? || loudest.zero?

      buckets.map { |peak| (((peak.to_f / loudest)**CURVE) * MAX_AMPLITUDE).round.clamp(0, MAX_AMPLITUDE) }
    end

    private

    # Every bucket exists even when the audio is shorter than the row is wide, so the
    # result is always the fixed length the contract types. A bucket no sample fell into is
    # silence, which is what a recording shorter than 64 frames actually has there.
    def bucket(samples)
      return Array.new(SAMPLES, 0) if samples.empty?

      width = samples.length / SAMPLES.to_f
      Array.new(SAMPLES) do |index|
        first = (index * width).floor
        last = [((index + 1) * width).ceil, samples.length].min
        slice = samples[first...last]
        slice.blank? ? 0 : slice.max_by(&:abs).abs
      end
    end

    def measurable?(attachment)
      attachment.present? && attachment.file.attached? &&
        attachment.file.byte_size.to_i.positive? &&
        attachment.file.byte_size <= MAX_MEASURED_BYTES &&
        ffmpeg.present?
    end

    # Read through a tempfile rather than piped in: ffmpeg seeks while it decodes, and a
    # container whose header sits at the end of the file (which is most of them) does not
    # decode from a stream it cannot rewind.
    def decode(attachment)
      attachment.file.blob.open do |file|
        # `binmode`, and the length read in bytes rather than through `present?`. What comes
        # back is raw PCM, and asking a String of arbitrary bytes whether it is blank runs a
        # whitespace match over it, which raises on the first byte that is not valid UTF-8.
        out, status = Open3.capture2(ffmpeg, '-v', 'error', '-i', file.path, *DECODE_FORMAT,
                                     '-ar', DECODE_RATE.to_s, '-', binmode: true)
        next nil unless status.success? && out.bytesize.positive?

        out.unpack('s<*')
      end
    end

    # Absent is "we cannot measure this", never zero. A deployment image carries ffmpeg
    # (docker/Dockerfile installs it), a developer's machine may not, and a bar of zeros
    # drawn because a binary was missing is a measurement of nothing presented as one.
    def ffmpeg
      return @ffmpeg if defined?(@ffmpeg)

      @ffmpeg = ENV.fetch('FFMPEG_PATH', nil).presence || find_ffmpeg
    end

    def find_ffmpeg
      path, status = Open3.capture2('/bin/sh', '-c', 'command -v ffmpeg')
      status.success? ? path.strip.presence : nil
    rescue StandardError
      nil
    end
  end
end
