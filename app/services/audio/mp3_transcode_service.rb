require 'open3'
require 'timeout'

module Audio; end

class Audio::Mp3TranscodeService
  TRANSCODABLE_CONTENT_TYPES = %w[
    application/ogg
    audio/ogg
    audio/opus
    audio/webm
    video/ogg
    video/webm
  ].freeze

  TRANSCODABLE_EXTENSIONS = %w[oga ogg opus webm].freeze
  DEFAULT_TIMEOUT_SECONDS = 60

  class TranscodeError < StandardError; end

  pattr_initialize [:attachment!]

  def self.requires_transcode?(attachment)
    content_type = normalized_content_type(attachment.file&.content_type)
    extension = attachment.extension.to_s.downcase
    filename_extension = File.extname(attachment.file&.filename.to_s).delete_prefix('.').downcase

    TRANSCODABLE_CONTENT_TYPES.include?(content_type) ||
      TRANSCODABLE_EXTENSIONS.include?(extension) ||
      TRANSCODABLE_EXTENSIONS.include?(filename_extension)
  end

  def self.normalized_content_type(content_type)
    content_type.to_s.downcase.split(';').first
  end

  def perform
    return attachment.file.blob unless self.class.requires_transcode?(attachment)
    return attachment.playback_file.blob if attachment.playback_file.attached?

    ensure_ffmpeg_available!
    transcode_and_attach!
  end

  private

  def transcode_and_attach!
    attachment.file.open do |source_file|
      output_file = Tempfile.new(['chatwit-audio-playback', '.mp3'])
      begin
        run_ffmpeg(source_file.path, output_file.path)
        output_file.rewind
        attachment.playback_file.attach(
          io: output_file,
          filename: playback_filename,
          content_type: 'audio/mpeg'
        )
        attachment.playback_file.blob
      ensure
        output_file.close
        output_file.unlink
      end
    end
  end

  def run_ffmpeg(source_path, output_path)
    stdout, stderr, status = nil

    Timeout.timeout(timeout_seconds) do
      stdout, stderr, status = Open3.capture3(*ffmpeg_command(source_path, output_path))
    end

    return if status.success? && File.size?(output_path)

    raise TranscodeError, stderr.presence || stdout.presence || 'ffmpeg did not create an MP3 file'
  rescue Timeout::Error
    raise TranscodeError, "ffmpeg exceeded #{timeout_seconds}s"
  end

  def ffmpeg_command(source_path, output_path)
    [
      'ffmpeg', '-hide_banner', '-loglevel', 'error',
      '-y', '-i', source_path, '-vn',
      '-acodec', 'libmp3lame', '-ar', '44100',
      '-ac', '1', '-b:a', '64k', output_path
    ]
  end

  def ensure_ffmpeg_available!
    return if system('ffmpeg', '-version', out: File::NULL, err: File::NULL)

    raise TranscodeError, 'ffmpeg is not available'
  end

  def timeout_seconds
    ENV.fetch('AUDIO_TRANSCODE_TIMEOUT_SECONDS', DEFAULT_TIMEOUT_SECONDS).to_i
  end

  def playback_filename
    base_name = File.basename(attachment.file.filename.to_s, '.*').presence || "audio-#{attachment.id}"
    "#{base_name}.mp3"
  end
end
