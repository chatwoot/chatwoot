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

  # Converts audio attachment to Instagram-compatible format if needed
  def self.convert_to_instagram_format(attachment)
    new.convert_to_instagram_format(attachment)
  end

  def convert_to_instagram_format(attachment)
    Rails.logger.info "Instagram: AudioConversionService called for attachment##{attachment.id} - content_type: #{attachment.file.content_type}, filename: #{attachment.file.filename}"
    
    unless should_convert_audio?(attachment)
      Rails.logger.info "Instagram: No conversion needed for attachment##{attachment.id}, returning original URL"
      return build_public_url(attachment)
    end

    Rails.logger.info "Instagram: Converting audio attachment##{attachment.id} to MP4 format for Instagram compatibility"

    begin
      original_file = download_attachment(attachment)
      mp4_file = convert_file_to_mp4(original_file)
      converted_url = upload_converted_file(attachment, mp4_file)

      Rails.logger.info "Instagram: Audio conversion successful for attachment##{attachment.id}. New URL: #{converted_url}"
      converted_url
    rescue StandardError => e
      Rails.logger.error "Instagram: Audio conversion failed for attachment##{attachment.id}: #{e.message}. Using original file as fallback."
      build_public_url(attachment)
    ensure
      cleanup_temp_files([original_file, mp4_file])
    end
  end

  private

  # Determines if audio file needs conversion to Instagram-compatible format
  def should_convert_audio?(attachment)
    return false unless attachment.file_type == 'audio' && attachment.file.attached?

    content_type = attachment.file.content_type
    file_size = attachment.file.byte_size

    # Check if file size exceeds Instagram limit
    if file_size > MAX_FILE_SIZE
      Rails.logger.warn "Instagram: Audio file size (#{file_size} bytes) exceeds Instagram limit (#{MAX_FILE_SIZE} bytes)"
      return false
    end

    # Convert OGG, Opus, and MP3 to MP4, allow other Instagram-compatible formats
    needs_conversion = %w[audio/ogg audio/opus audio/mpeg audio/mp3].include?(content_type)
    
    Rails.logger.info "Instagram: Audio format #{content_type} #{needs_conversion ? 'needs' : 'does not need'} conversion"
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
      '-c:a', 'aac',               # AAC codec (widely supported in MP4)
      '-b:a', '128k',              # Bitrate optimized for Instagram
      '-ar', '44100',              # Sample rate
      '-ac', '2',                  # Stereo channel
      '-movflags', '+faststart',   # Optimize for streaming
      '-f', 'mp4',                 # MP4 container
      '-vn',                       # No video stream (audio only)
      '-y', output_file.path       # Overwrite output file
    ]

    Rails.logger.info "Instagram: Running FFmpeg command: #{command.join(' ')}"
    
    success = system(*command, out: File::NULL, err: File::NULL)
    raise "FFmpeg conversion failed (exit status: #{$?.exitstatus})" unless success && File.size?(output_file.path)

    # Check if converted file size exceeds Instagram limit
    if File.size(output_file.path) > MAX_FILE_SIZE
      raise "Converted file size (#{File.size(output_file.path)} bytes) exceeds Instagram limit (#{MAX_FILE_SIZE} bytes)"
    end

    Rails.logger.info "Instagram: Conversion successful. Output file size: #{File.size(output_file.path)} bytes"
    output_file
  end

  # Uploads converted file and returns public URL
  def upload_converted_file(original_attachment, mp4_file)
    # Store reference to original blob before replacement
    original_blob = original_attachment.file.blob if original_attachment.file.attached?
    
    # Create new blob with Instagram-compatible format
    new_blob = ActiveStorage::Blob.create_and_upload!(
      io: mp4_file,
      filename: "#{original_attachment.file.filename.base}.m4a",
      content_type: 'audio/mp4'
    )

    # Update the attachment to use the converted file for Chatwoot interface
    original_attachment.file.attach(new_blob)
    
    # Safely remove the original blob to prevent storage bloat
    if original_blob && original_blob != new_blob
      Rails.logger.info "Instagram: Removing original blob##{original_blob.id} after successful conversion"
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