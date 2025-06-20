# app/services/whatsapp/audio_conversion_service.rb

# Handles audio file conversion to WhatsApp-compatible format (OGG+Opus).
# This service ensures all audio attachments meet WHAPI's strict format requirements.
class Whatsapp::AudioConversionService
  include Rails.application.routes.url_helpers

  # Converts audio attachment to OGG+Opus format if needed
  def self.convert_to_whatsapp_format(attachment)
    new.convert_to_whatsapp_format(attachment)
  end

  def convert_to_whatsapp_format(attachment)
    return build_public_url(attachment) unless should_convert_audio?(attachment)

    Rails.logger.info "WHAPI: Converting audio attachment##{attachment.id} to OGG+Opus format for WhatsApp compatibility"

    begin
      original_file = download_attachment(attachment)
      ogg_file = convert_file_to_ogg_opus(original_file)
      converted_url = upload_converted_file(attachment, ogg_file)

      Rails.logger.info "WHAPI: Audio conversion successful for attachment##{attachment.id}. New URL: #{converted_url}"
      converted_url
    rescue StandardError => e
      Rails.logger.error "WHAPI: Audio conversion failed for attachment##{attachment.id}: #{e.message}. Using original file as fallback."
      build_public_url(attachment)
    ensure
      cleanup_temp_files([original_file, ogg_file])
    end
  end

  private

  # Determines if audio file needs conversion to WhatsApp-compatible format
  def should_convert_audio?(attachment)
    return false unless attachment.file_type == 'audio' && attachment.file.attached?

    content_type = attachment.file.content_type
    # Convert unless already in WhatsApp-compatible format
    !whatsapp_compatible_format?(content_type)
  end

  # Checks if content type is already WhatsApp-compatible
  def whatsapp_compatible_format?(content_type)
    # Whapi supports audio/ogg format (without codec specification)
    content_type == 'audio/ogg' || content_type.start_with?('audio/ogg')
  end

  # Downloads attachment to temporary file for processing
  def download_attachment(attachment)
    temp_file = Tempfile.new(['whapi_audio_', File.extname(attachment.file.filename.to_s)])
    temp_file.binmode
    attachment.file.download { |chunk| temp_file.write(chunk) }
    temp_file.rewind
    temp_file
  end

  # Converts input file to OGG+Opus format using FFmpeg
  def convert_file_to_ogg_opus(input_file)
    verify_ffmpeg_availability

    output_file = Tempfile.new(['whapi_converted_', '.ogg'])

    # FFmpeg command optimized for WhatsApp voice messages
    # - OGG container with Opus codec (required by WhatsApp)
    # - Mono channel (required by WhatsApp)
    # - Optimized for voice compression
    command = [
      'ffmpeg', '-i', input_file.path,
      '-c:a', 'libopus',           # Opus codec (required)
      '-b:a', '64k',               # Bitrate optimized for voice
      '-ar', '48000',              # Sample rate
      '-ac', '1',                  # Mono channel (required by WhatsApp)
      '-application', 'voip',      # Optimize for voice
      '-frame_duration', '20',     # Frame duration
      '-compression_level', '10',  # Max compression
      '-f', 'ogg',                 # OGG container (required)
      '-y', output_file.path       # Overwrite output file
    ]

    success = system(*command, out: File::NULL, err: File::NULL)
    raise "FFmpeg conversion failed (exit status: #{$?.exitstatus})" unless success && File.size?(output_file.path)

    output_file
  end

  # Uploads converted file and returns public URL
  def upload_converted_file(original_attachment, ogg_file)
    # Create new blob with Whapi-compatible format
    new_blob = ActiveStorage::Blob.create_and_upload!(
      io: ogg_file,
      filename: "#{original_attachment.file.filename.base}.ogg",
      content_type: 'audio/ogg'
    )

    # Update the attachment to use the converted file for Chatwoot interface
    original_attachment.file.attach(new_blob)

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

    raise 'FFmpeg is not installed. Please install FFmpeg to enable audio conversion for WhatsApp compatibility.'
  end

  # Cleans up temporary files
  def cleanup_temp_files(files)
    files.compact.each do |file|
      next unless file.respond_to?(:close)

      file.close
      file.unlink if file.respond_to?(:unlink)
    rescue StandardError => e
      Rails.logger.warn "WHAPI: Failed to cleanup temp file: #{e.message}"
    end
  end
end