module FileTypeHelper
  def file_type(content_type)
    return :image if [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/tiff',
      'image/bmp'
    ].include?(content_type)

    return :video if content_type.include?('video/')
    return :audio if content_type.include?('audio/')

    :file
  end
end
