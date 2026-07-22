module FileTypeHelper
  # NOTE: video, audio, image, etc are filetypes previewable in frontend
  GENERIC_CONTENT_TYPES = %w[application/octet-stream binary/octet-stream].freeze

  # Used when browsers/uploaders send a generic MIME for real audio files.
  AUDIO_EXTENSION_MIME_TYPES = {
    'ogg' => 'audio/ogg',
    'oga' => 'audio/ogg',
    'opus' => 'audio/ogg',
    'mp3' => 'audio/mpeg',
    'mpeg' => 'audio/mpeg',
    'mpga' => 'audio/mpeg',
    'm4a' => 'audio/mp4',
    'aac' => 'audio/aac',
    'wav' => 'audio/wav',
    'amr' => 'audio/amr'
  }.freeze

  def file_type(content_type)
    return :image if image_file?(content_type)
    return :video if video_file?(content_type)
    return :audio if content_type&.include?('audio/')

    :file
  end

  # Used in case of DIRECT_UPLOADS_ENABLED=true
  def file_type_by_signed_id(signed_id)
    blob = ActiveStorage::Blob.find_signed(signed_id)
    file_type(blob&.content_type)
  end

  def resolve_audio_content_type(content_type, filename)
    return content_type if content_type&.include?('audio/')

    extension = File.extname(filename.to_s).delete_prefix('.').downcase
    mime = AUDIO_EXTENSION_MIME_TYPES[extension]
    return content_type if mime.blank?
    return mime if content_type.blank? || GENERIC_CONTENT_TYPES.include?(content_type)

    content_type
  end

  def voice_note_content_type?(content_type)
    %w[audio/ogg audio/opus].include?(content_type)
  end

  def image_file?(content_type)
    [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/bmp',
      'image/webp',
      'image'
    ].include?(content_type)
  end

  def video_file?(content_type)
    [
      'video/ogg',
      'video/mp4',
      'video/webm',
      'video/quicktime',
      'video'
    ].include?(content_type)
  end
end
