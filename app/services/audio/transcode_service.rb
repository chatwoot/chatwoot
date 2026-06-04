class Audio::TranscodeService
  SUPPORTED_FORMATS = { 'opus' => { codec: 'libopus', extension: 'ogg', content_type: 'audio/ogg' } }.freeze

  def initialize(attachment, target_format, source_file: nil)
    @attachment = attachment
    @target_format = target_format
    @source_file = source_file
  end

  def perform
    validate_format!
    return if already_in_target_format?

    transcode_attachment
  end

  private

  def already_in_target_format?
    format_config = SUPPORTED_FORMATS[@target_format]
    content_type = @attachment.file.content_type
    return true if content_type == format_config[:content_type]

    # Marcel may detect Opus-in-OGG as audio/opus; treat as already in target format
    # when transcoding to Opus to avoid unnecessary re-transcoding
    @target_format == 'opus' && content_type == 'audio/opus'
  end

  def validate_format!
    return if SUPPORTED_FORMATS.key?(@target_format)

    raise CustomExceptions::Audio::UnsupportedFormatError,
          "Unsupported transcode format: #{@target_format}. Supported: #{SUPPORTED_FORMATS.keys.join(', ')}"
  end

  def transcode_attachment
    format_config = SUPPORTED_FORMATS[@target_format]
    input_file = nil
    output_file = nil
    input_file = download_to_tempfile
    output_file = Tempfile.new(['transcoded', ".#{format_config[:extension]}"])
    movie = FFMPEG::Movie.new(input_file.path)
    raise CustomExceptions::Audio::TranscodingError, 'Invalid or unreadable audio file' unless movie.valid?

    movie.transcode(output_file.path, audio_codec: format_config[:codec], custom: %w[-vn -map_metadata -1])
    replace_attachment_file(output_file, format_config)
  rescue FFMPEG::Error => e
    raise CustomExceptions::Audio::TranscodingError, "FFmpeg transcoding failed: #{e.message}"
  ensure
    input_file&.close!
    output_file&.close!
  end

  def download_to_tempfile
    tempfile = Tempfile.new(['original_audio', File.extname(@attachment.file.filename.to_s)])
    tempfile.binmode
    if @source_file && (@source_file.respond_to?(:tempfile) || @source_file.respond_to?(:path))
      source_path = @source_file.respond_to?(:tempfile) ? @source_file.tempfile.path : @source_file.path
      IO.copy_stream(source_path, tempfile)
    else
      @attachment.file.blob.open { |file| IO.copy_stream(file, tempfile) }
    end
    tempfile.rewind
    tempfile
  end

  def replace_attachment_file(output_file, format_config)
    filename = "#{File.basename(@attachment.file.filename.to_s, '.*')}.#{format_config[:extension]}"
    File.open(output_file.path, 'rb') do |file|
      @attachment.file.attach(
        io: file,
        filename: filename,
        content_type: format_config[:content_type]
      )
    end
    @attachment.file_type = :audio
  end
end
