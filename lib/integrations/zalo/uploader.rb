class Integrations::Zalo::Uploader < Integrations::Zalo::Authenticated
  FILE_LIMIT = 5 * 1024 * 1024 # 5MB
  IMAGE_LIMIT = 1 * 1024 * 1024 # 1MB

  def upload_image(url)
    tempfile = Down.download(url, max_size: IMAGE_LIMIT)
    form_uploader(tempfile).post('v2.0/oa/upload/image')
  rescue Down::Error => e
    raise "Image upload failed: #{e.message}"
  rescue Integrations::Zalo::Client::Error => e
    raise "Zalo: #{e.message}"
  end

  def upload_file(url)
    tempfile = Down.download(url, max_size: FILE_LIMIT)
    form_uploader(tempfile).post('v2.0/oa/upload/file')
  rescue Down::Error => e
    raise "File upload failed: #{e.message}"
  rescue Integrations::Zalo::Client::Error => e
    raise "Zalo: #{e.message}"
  end

  def upload_gif(url)
    tempfile = Down.download(url, max_size: FILE_LIMIT)
    form_uploader(tempfile).post('v2.0/oa/upload/gif')
  rescue Down::Error => e
    raise "GIF upload failed: #{e.message}"
  rescue Integrations::Zalo::Client::Error => e
    raise "Zalo: #{e.message}"
  end

  private

  def form_uploader(tempfile)
    client.form_data!.body(file: tempfile)
  end
end
