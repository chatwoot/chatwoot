# frozen-string-literal: true

gem "http", ">= 2.1.0", "< 6"

require "http"

require "down/backend"

require "tempfile"

module Down
  # Provides streaming downloads implemented with HTTP.rb.
  class Http < Backend
    # Initializes the backend with common defaults.
    def initialize(**options, &block)
      @method = options.delete(:method) || :get
      @client = HTTP
        .headers("User-Agent" => "Down/#{Down::VERSION}")
        .follow(max_hops: 2)
        .timeout(connect: 30, write: 30, read: 30)

      @client = HTTP::Client.new(@client.default_options.merge(options)) if options.any?
      @client = block.call(@client) if block
    end

    # Downlods the remote file to disk. Accepts HTTP.rb options via a hash or a
    # block, and some additional options as well.
    def download(url, max_size: nil, progress_proc: nil, content_length_proc: nil, destination: nil, extension: nil, **options, &block)
      response = request(url, **options, &block)

      content_length_proc.call(response.content_length) if content_length_proc && response.content_length

      if max_size && response.content_length && response.content_length > max_size
        raise Down::TooLarge, "file is too large (#{response.content_length/1024/1024}MB, max is #{max_size/1024/1024}MB)"
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

      tempfile.extend Down::Http::DownloadedFile
      tempfile.url     = response.uri.to_s
      tempfile.headers = normalize_headers(response.headers.to_h)

      download_result(tempfile, destination)
    rescue
      tempfile.close! if tempfile
      raise
    end

    # Starts retrieving the remote file and returns an IO-like object which
    # downloads the response body on-demand. Accepts HTTP.rb options via a hash
    # or a block.
    def open(url, rewindable: true, **options, &block)
      response = request(url, **options, &block)

      Down::ChunkedIO.new(
        chunks:     enum_for(:stream_body, response),
        size:       response.content_length,
        encoding:   response.content_type.charset,
        rewindable: rewindable,
        data:       {
          status:   response.code,
          headers:  normalize_headers(response.headers.to_h),
          response: response
        },
      )
    end

    private

    def request(url, method: @method, **options, &block)
      response = send_request(method, url, **options, &block)
      response_error!(response) unless response.status.success?
      response
    end

    def send_request(method, url, **options, &block)
      uri = HTTP::URI.parse(url)

      client = @client
      client = client.basic_auth(user: uri.user, pass: uri.password) if uri.user || uri.password
      client = block.call(client) if block

      client.request(method, url, options)
    rescue => exception
      request_error!(exception)
    end

    # Yields chunks of the response body to the block.
    def stream_body(response, &block)
      response.body.each(&block)
    rescue => exception
      request_error!(exception)
    ensure
      response.connection.close unless @client.persistent?
    end

    # Raises non-sucessful response as a Down::ResponseError.
    def response_error!(response)
      args = [response.status.to_s, response]

      case response.code
      when 404      then raise Down::NotFound.new(*args)
      when 400..499 then raise Down::ClientError.new(*args)
      when 500..599 then raise Down::ServerError.new(*args)
      else               raise Down::ResponseError.new(*args)
      end
    end

    # Re-raise HTTP.rb exceptions as Down::Error exceptions.
    def request_error!(exception)
      case exception
      when HTTP::Request::UnsupportedSchemeError, Addressable::URI::InvalidURIError
        raise Down::InvalidUrl, exception.message
      when HTTP::ConnectionError
        raise Down::ConnectionError, exception.message
      when HTTP::TimeoutError
        raise Down::TimeoutError, exception.message
      when HTTP::Redirector::TooManyRedirectsError
        raise Down::TooManyRedirects, exception.message
      when OpenSSL::SSL::SSLError
        raise Down::SSLError, exception.message
      else
        raise exception
      end
    end

    # Defines some additional attributes for the returned Tempfile.
    module DownloadedFile
      attr_accessor :url, :headers

      def original_filename
        Utils.filename_from_content_disposition(headers["Content-Disposition"]) ||
        Utils.filename_from_path(HTTP::URI.parse(url).path)
      end

      def content_type
        HTTP::ContentType.parse(headers["Content-Type"]).mime_type
      end

      def charset
        HTTP::ContentType.parse(headers["Content-Type"]).charset
      end
    end
  end
end
