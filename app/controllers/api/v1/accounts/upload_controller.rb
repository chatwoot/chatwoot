class Api::V1::Accounts::UploadController < Api::V1::Accounts::BaseController
  def create
    result = if params[:attachment].present?
               create_from_file
             elsif params[:external_url].present?
               create_from_url
             else
               render_error('No file or URL provided', :unprocessable_entity)
             end

    render_success(result) if result.is_a?(ActiveStorage::Blob)
  end

  private

  def create_from_file
    attachment = params[:attachment]
    create_and_save_blob(attachment.tempfile, attachment.original_filename, attachment.content_type)
  end

  def create_from_url
    fetch_and_process_file_from_url(params[:external_url].to_s)
  end

  def fetch_and_process_file_from_url(url)
    uri = URI.parse(url)
    filename = File.basename(uri.path)
    response = nil
    # ActiveStorage reads the IO more than once (checksum + upload), so we need a rewindable buffer.
    # A Tempfile gives us that without loading the full response into memory like StringIO would if we did StringIO.new(response.body)
    tempfile = Tempfile.new('chatwoot-external-upload')

    # Fetch via ssrf_filter which validates scheme/host, resolves DNS safely, and re-validates redirects.
    SsrfFilter.get(url) do |res|
      response = res
      res.read_body { |chunk| tempfile.write(chunk) }
    end

    unless response.is_a?(Net::HTTPSuccess)
      render_error("Failed to fetch file from URL: #{response.code} #{response.message}", :unprocessable_entity)
      return
    end

    tempfile.rewind
    create_and_save_blob(tempfile, filename, response['content-type'])
  rescue SsrfFilter::Error, URI::InvalidURIError, SocketError, Resolv::ResolvError
    render_error('Invalid URL provided', :unprocessable_entity)
  rescue StandardError
    render_error('An unexpected error occurred', :internal_server_error)
  ensure
    tempfile&.close!
  end

  def create_and_save_blob(io, filename, content_type)
    ActiveStorage::Blob.create_and_upload!(
      io: io,
      filename: filename,
      content_type: content_type
    )
  end

  def render_success(file_blob)
    render json: { file_url: url_for(file_blob), blob_id: file_blob.signed_id }
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
