# frozen-string-literal: true

require "uri"
require "tempfile"
require "httpx"

require "down/backend"


module Down
  # Provides streaming downloads implemented with HTTPX.
  class Httpx < Backend
    # Initializes the backend

    USER_AGENT = "Down/#{Down::VERSION}"

    def initialize(**options, &block)
      @method = options.delete(:method) || :get
      headers = options.delete(:headers) || {}
      @client = HTTPX
          .plugin(:follow_redirects, max_redirects: 2)
          .plugin(:basic_authentication)
          .plugin(:stream)
          .with(
            headers: { "user-agent": USER_AGENT }.merge(headers),
            timeout: { connect_timeout: 30, write_timeout: 30, read_timeout: 30 },
            **options
          )

      @client = block.call(@client) if block
    end


    # Downlods the remote file to disk. Accepts HTTPX options via a hash or a
    # block, and some additional options as well.
    def download(url, max_size: nil, progress_proc: nil, content_length_proc: nil, destination: nil, extension: nil, **options, &block)
      client = @client

      response = request(client, url, **options, &block)

      content_length = nil

      if response.headers.key?("content-length")
        content_length = response.headers["content-length"].to_i

        content_length_proc.call(content_length) if content_length_proc

        if max_size && content_length > max_size
          response.close
          raise Down::TooLarge, "file is too large (#{content_length/1024/1024}MB, max is #{max_size/1024/1024}MB)"
        end
      end

      extname  = extension ? ".#{extension}" : File.extname(response.uri.path)
      tempfile = Tempfile.new(["down-http", extname], binmode: true)

      stream_body(response) do |chunk|
        tempfile.write(chunk)
        chunk.clear # deallocate string

        progress_proc.call(tempfile.size) if progress_proc

        if max_size && tempfile.size > max_size
          raise Down::TooLarge, "file is too large (#{tempfile.size/1024/1024}MB, max is #{max_size/1024/1024}MB)"
        end
      end

      tempfile.open # flush written content

      tempfile.extend DownloadedFile
      tempfile.url     = response.uri.to_s
      tempfile.headers = normalize_headers(response.headers.to_h)
      tempfile.content_type = response.content_type.mime_type
      tempfile.charset = response.body.encoding

      download_result(tempfile, destination)
    rescue
      tempfile.close! if tempfile
      raise
    end

    # Starts retrieving the remote file and returns an IO-like object which
    # downloads the response body on-demand. Accepts HTTP.rb options via a hash
    # or a block.
    def open(url, rewindable: true, **options, &block)
      response = request(@client, url, stream: true, **options, &block)
      size = response.headers["content-length"]
      size = size.to_i if size
      Down::ChunkedIO.new(
        chunks:     enum_for(:stream_body, response),
        size:       size,
        encoding:   response.body.encoding,
        rewindable: rewindable,
        data:       {
          status:   response.status,
          headers:  normalize_headers(response.headers.to_h),
          response: response
        },
      )
    end

    private

    # Yields chunks of the response body to the block.
    def stream_body(response, &block)
      response.each(&block)
    rescue => exception
      request_error!(exception)
    end

    def request(client, url, method: @method, **options, &block)
      response = send_request(client, method, url, **options, &block)
      response.raise_for_status
      response_error!(response) unless (200..299).include?(response.status)
      response
    rescue HTTPX::HTTPError
      response_error!(response)
    rescue => error
      request_error!(error)
    end

    def send_request(client, method, url, **options, &block)
      uri = URI(url)
      client = @client
      if uri.user || uri.password
        client = client.basic_auth(uri.user, uri.password)
        uri.user = uri.password = nil
      end
      client = block.call(client) if block

      client.request(method, uri, stream: true, **options)
    rescue => exception
      request_error!(exception)
    end

    # Raises non-sucessful response as a Down::ResponseError.
    def response_error!(response)
      args = [response.status.to_s, response]

      case response.status
      when 300..399 then raise Down::TooManyRedirects, "too many redirects"
      when 404      then raise Down::NotFound.new(*args)
      when 400..499 then raise Down::ClientError.new(*args)
      when 500..599 then raise Down::ServerError.new(*args)
      else               raise Down::ResponseError.new(*args)
      end
    end

    # Re-raise HTTP.rb exceptions as Down::Error exceptions.
    def request_error!(exception)
      case exception
      when URI::Error, HTTPX::UnsupportedSchemeError
        raise Down::InvalidUrl, exception.message
      when HTTPX::ConnectionError
        raise Down::ConnectionError, exception.message
      when HTTPX::TimeoutError
        raise Down::TimeoutError, exception.message
      when OpenSSL::SSL::SSLError
        raise Down::SSLError, exception.message
      else
        raise exception
      end
    end

    # Defines some additional attributes for the returned Tempfile.
    module DownloadedFile
      attr_accessor :url, :headers, :charset, :content_type

      def original_filename
        Utils.filename_from_content_disposition(headers["Content-Disposition"]) ||
        Utils.filename_from_path(URI.parse(url).path)
      end
    end
  end
end