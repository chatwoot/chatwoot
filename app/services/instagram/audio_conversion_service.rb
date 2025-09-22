# app/services/instagram/audio_conversion_service.rb

# Handles audio file conversion to Instagram-compatible format (audio MP4/M4A).
# This service ensures all audio attachments meet Instagram's format requirements.
class Instagram::AudioConversionService
  include Rails.application.routes.url_helpers

  # Instagram supported audio formats and their MIME types
  INSTAGRAM_AUDIO_FORMATS = {
    'aac' => 'audio/aac',
    'm4a' => 'audio/mp4',
    'mp4' => 'audio/mp4',  # Audio-only MP4
    'wav' => 'audio/wav'
  }.freeze

  # Maximum file size for Instagram audio (25MB)
  MAX_FILE_SIZE = 25.megabytes

  # File type constants for consistency with Attachment model enum
  AUDIO_FILE_TYPE = 'audio'.freeze

  # Converts audio attachment to Instagram-compatible format if needed
  def self.convert_to_instagram_format(attachment)
    new.convert_to_instagram_format(attachment)
  end

  def convert_to_instagram_format(attachment)
    Rails.logger.info "[INSTAGRAM_AUDIO] Starting conversion for attachment##{attachment.id} - " \
                      "content_type: #{attachment.file.content_type}, filename: #{attachment.file.filename}, " \
                      "size: #{attachment.file.byte_size} bytes, file_type: #{attachment.file_type}"

    unless should_convert_audio?(attachment)
      Rails.logger.info "[INSTAGRAM_AUDIO] No conversion needed for attachment##{attachment.id}, returning original URL"
      return build_public_url(attachment)
    end

    Rails.logger.info "[INSTAGRAM_AUDIO] Converting attachment##{attachment.id} to MP4 format for Instagram compatibility"

    begin
      original_file = download_attachment(attachment)
      Rails.logger.info "[INSTAGRAM_AUDIO] Downloaded original file for attachment##{attachment.id}, temp_path: #{original_file.path}"

      mp4_file = convert_file_to_mp4(original_file)
      Rails.logger.info "[INSTAGRAM_AUDIO] FFmpeg conversion completed for attachment##{attachment.id}, " \
                        "output_size: #{File.size(mp4_file.path)} bytes"
      converted_url = upload_converted_file(attachment, mp4_file)

      Rails.logger.info "[INSTAGRAM_AUDIO] Conversion successful for attachment##{attachment.id}. URL: #{converted_url}"
      converted_url
    rescue StandardError => e
      Rails.logger.error "[INSTAGRAM_AUDIO] Conversion failed for attachment##{attachment.id}: #{e.message}. " \
                         "Backtrace: #{e.backtrace.first(3).join(', ')}. Using original file as fallback."
      build_public_url(attachment)
    ensure
      cleanup_temp_files([original_file, mp4_file])
    end
  end

  private

  # Determines if audio file needs conversion to Instagram-compatible format
  def should_convert_audio?(attachment)
    return false unless attachment.file_type == AUDIO_FILE_TYPE && attachment.file.attached?

    content_type = attachment.file.content_type
    file_size = attachment.file.byte_size

    # Check if file size exceeds Instagram limit
    if file_size > MAX_FILE_SIZE
      Rails.logger.warn "[INSTAGRAM_AUDIO] Audio file size (#{file_size} bytes) exceeds Instagram limit " \
                        "(#{MAX_FILE_SIZE} bytes) for attachment##{attachment.id}"
      return false
    end

    # Convert OGG, Opus, and MP3 to MP4, allow other Instagram-compatible formats
    needs_conversion = %w[audio/ogg audio/opus audio/mpeg audio/mp3].include?(content_type)

    Rails.logger.info "[INSTAGRAM_AUDIO] Audio format #{content_type} #{needs_conversion ? 'needs' : 'does not need'} " \
                      "conversion for attachment##{attachment.id}"
    needs_conversion
  end

  # Downloads attachment to temporary file for processing
  def download_attachment(attachment)
    temp_file = Tempfile.new(['instagram_audio_', File.extname(attachment.file.filename.to_s)])
    temp_file.binmode
    attachment.file.download { |chunk| temp_file.write(chunk) }
    temp_file.rewind
    temp_file
  end

  # Converts input file to audio MP4 format using FFmpeg
  def convert_file_to_mp4(input_file)
    verify_ffmpeg_availability

    # Use MP4 container with AAC codec (audio-only MP4)
    output_file = Tempfile.new(['instagram_converted_', '.m4a'])

    # FFmpeg command to convert to audio-only MP4 (M4A)
    command = [
      'ffmpeg', '-i', input_file.path,
      '-c:a', 'aac',
      '-b:a', '128k',
      '-ar', '44100',
      '-ac', '2',
      '-movflags', '+faststart',
      '-f', 'mp4',
      '-vn',
      '-y', output_file.path
    ]

    Rails.logger.info "[INSTAGRAM_AUDIO] Running FFmpeg command: #{command.join(' ')}"

    success = system(*command, out: File::NULL, err: File::NULL)
    exit_status = $CHILD_STATUS.exitstatus

    unless success && File.size?(output_file.path)
      Rails.logger.error "[INSTAGRAM_AUDIO] FFmpeg conversion failed (exit status: #{exit_status})"
      raise "FFmpeg conversion failed (exit status: #{exit_status})"
    end

    # Check if converted file size exceeds Instagram limit
    output_size = File.size(output_file.path)
    if output_size > MAX_FILE_SIZE
      Rails.logger.error "[INSTAGRAM_AUDIO] Converted file size (#{output_size} bytes) exceeds Instagram limit (#{MAX_FILE_SIZE} bytes)"
      raise "Converted file size (#{output_size} bytes) exceeds Instagram limit (#{MAX_FILE_SIZE} bytes)"
    end

    Rails.logger.info "[INSTAGRAM_AUDIO] FFmpeg conversion successful. Output file size: #{output_size} bytes"
    output_file
  end

  # Uploads converted file and returns public URL
  def upload_converted_file(original_attachment, mp4_file)
    # Store reference to original blob and file_type before replacement
    original_blob = original_attachment.file.blob if original_attachment.file.attached?
    original_file_type = original_attachment.file_type

    # Create new blob with Instagram-compatible format
    new_blob = ActiveStorage::Blob.create_and_upload!(
      io: mp4_file,
      filename: "#{original_attachment.file.filename.base}.m4a",
      content_type: 'audio/mp4'
    )

    # Update the attachment to use the converted file for Chatwoot interface
    original_attachment.file.attach(new_blob)

    # Preserve original file_type to maintain audio classification for Instagram API
    #
    # When we attach a new MP4 blob, Rails might automatically infer the file_type
    # as "video" based on the MP4 container format, even though it's audio-only content.
    # We explicitly preserve the "audio" classification to ensure:
    # 1. Instagram API receives type: "audio" instead of type: "video"
    # 2. Audio attachments continue to trigger proper conversion flow
    # 3. UI shows correct audio player instead of video player
    if original_file_type == AUDIO_FILE_TYPE
      original_attachment.update!(file_type: original_file_type)
      Rails.logger.info "[INSTAGRAM_AUDIO] Preserved file_type as '#{original_file_type}' for attachment##{original_attachment.id}"
    end

    # Safely remove the original blob to prevent storage bloat
    if original_blob && original_blob != new_blob
      Rails.logger.info "[INSTAGRAM_AUDIO] Removing original blob##{original_blob.id} after successful conversion"
      original_blob.purge
    end

    build_public_url_for_blob(new_blob)
  end

  # Builds public URL for attachment using configured frontend URL
  def build_public_url(attachment)
    build_public_url_for_blob(attachment.file)
  end

  # Builds public URL for blob using configured frontend URL
  def build_public_url_for_blob(blob)
    host = ENV.fetch('FRONTEND_URL', "http://localhost:#{ENV.fetch('PORT', 3000)}")
    rails_blob_url(blob, host: host)
  end

  # Verifies FFmpeg is available on the system
  def verify_ffmpeg_availability
    return if system('which ffmpeg > /dev/null 2>&1')

    raise 'FFmpeg is not installed. Please install FFmpeg to enable audio conversion for Instagram compatibility.'
  end

  # Cleans up temporary files
  def cleanup_temp_files(files)
    files.compact.each do |file|
      next unless file.respond_to?(:close)

      file.close
      file.unlink if file.respond_to?(:unlink)
    rescue StandardError => e
      Rails.logger.warn "Instagram: Failed to cleanup temp file: #{e.message}"
    end
  end
end