require 'streamio-ffmpeg'

# Transcodes inbound voice notes (OGG/Opus/WebM) to MP3 so every client — iOS Safari,
# Android MediaPlayer, desktop browsers — can play them natively. See issue #13210.
#
# Returns a hash: { transcoded: true, io:, filename:, content_type: } on success, or
# { transcoded: false } for non-audio input, unsupported formats, a missing ffmpeg binary,
# or any transcode failure (which is reported and swallowed so the original is kept).
class Audio::TranscoderService
  TRANSCODABLE_MIME = %w[audio/ogg audio/opus audio/webm application/ogg audio/x-opus+ogg].freeze
  TRANSCODABLE_EXT  = %w[.ogg .oga .opus .weba .webm].freeze

  def initialize(io:, filename:, content_type:)
    @io = io
    @filename = filename.to_s
    @content_type = content_type.to_s
  end

  def perform
    return { transcoded: false } unless should_transcode? && ffmpeg_available?

    {
      transcoded: true,
      io: StringIO.new(transcode!),
      filename: rename_to_mp3(@filename),
      content_type: 'audio/mpeg'
    }
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    { transcoded: false }
  end

  private

  def should_transcode?
    return true if TRANSCODABLE_MIME.include?(@content_type)

    TRANSCODABLE_EXT.any? { |ext| @filename.downcase.end_with?(ext) }
  end

  def ffmpeg_available?
    return @ffmpeg_available unless @ffmpeg_available.nil?

    @ffmpeg_available = system('which ffmpeg > /dev/null 2>&1')
    Rails.logger.warn('[Audio::TranscoderService] ffmpeg not found in PATH; keeping original audio.') unless @ffmpeg_available
    @ffmpeg_available
  end

  # Reads the transcoded bytes into memory and unlinks both temp files before returning,
  # so nothing accumulates in /tmp (the io is consumed by ActiveStorage later, by which
  # point the source/output files are already gone).
  def transcode!
    source = output = nil
    source = write_to_tempfile
    output = Tempfile.new(['cw-audio-out', '.mp3'])
    output.close

    FFMPEG::Movie.new(source.path).transcode(
      output.path,
      audio_codec: 'libmp3lame',
      audio_bitrate: 64, # mono voice → 64 kbps is plenty
      audio_channels: 1,
      audio_sample_rate: 44_100,
      custom: %w[-vn -y]
    )
    File.binread(output.path)
  ensure
    cleanup(source)
    cleanup(output)
  end

  def write_to_tempfile
    @io.rewind if @io.respond_to?(:rewind)
    tmp = Tempfile.new(['cw-audio-src', File.extname(@filename).presence || '.ogg'])
    tmp.binmode
    IO.copy_stream(@io, tmp)
    tmp.flush
    # Leave the source rewound so the keep-original fallback (transcode failure) uploads the
    # full file instead of a stream already consumed to EOF by the copy above.
    @io.rewind if @io.respond_to?(:rewind)
    tmp
  end

  def cleanup(tempfile)
    return if tempfile.nil?

    tempfile.close unless tempfile.closed?
    tempfile.unlink
  rescue StandardError
    nil
  end

  def rename_to_mp3(name)
    "#{File.basename(name.presence || 'audio', '.*')}.mp3"
  end
end
