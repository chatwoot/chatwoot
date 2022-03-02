module FileTypeHelper
  # NOTE: video, audio, image, etc are filetypes previewable in frontend
  def file_type(content_type)
    return :image if image_file?(content_type)
    return :video if video_file?(content_type)
    return :audio if content_type&.include?('audio/')

    :file
  end

  def image_file?(content_type)
    [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/bmp',
      'image/webp'
    ].include?(content_type)
  end

  def video_file?(content_type)
    [
      'video/ogg',
      'video/mp4',
      'video/webm',
      'video/quicktime'
    ].include?(content_type)
  end
end
