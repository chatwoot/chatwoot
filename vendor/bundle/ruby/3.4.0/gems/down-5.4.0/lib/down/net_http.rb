# frozen-string-literal: true

require "open-uri"
require "net/https"
require "addressable/uri"

require "down/backend"

require "tempfile"
require "fileutils"

module Down
  # Provides streaming downloads implemented with Net::HTTP and open-uri.
  class NetHttp < Backend
    URI_NORMALIZER = -> (url) do
      addressable_uri = Addressable::URI.parse(url)
      addressable_uri.normalize.to_s
    end

    # Initializes the backend with common defaults.
    def initialize(*args, **options)
      @options = merge_options({
        headers:        { "User-Agent" => "Down/#{Down::VERSION}" },
        max_redirects:  2,
        open_timeout:   30,
        read_timeout:   30,
        uri_normalizer: URI_NORMALIZER,
      }, *args, **options)
    end

    # Downloads a remote file to disk using open-uri. Accepts any open-uri
    # options, and a few more.
    def download(url, *args, **options)
      options = merge_options(@options, *args, **options)

      max_size            = options.delete(:max_size)
      max_redirects       = options.delete(:max_redirects)
      progress_proc       = options.delete(:progress_proc)
      content_length_proc = options.delete(:content_length_proc)
      destination         = options.delete(:destination)
      headers             = options.delete(:headers)
      uri_normalizer      = options.delete(:uri_normalizer)
      extension           = options.delete(:extension)

      # Use open-uri's :content_lenth_proc or :progress_proc to raise an
      # exception early if the file is too large.
      #
      # Also disable following redirects, as we'll provide our own
      # implementation that has the ability to limit the number of redirects.
      open_uri_options = {
        content_length_proc: proc { |size|
          if size && max_size && size > max_size
            raise Down::TooLarge, "file is too large (#{size/1024/1024}MB, max is #{max_size/1024/1024}MB)"
          end
          content_length_proc.call(size) if content_length_proc
        },
        progress_proc: proc { |current_size|
          if max_size && current_size > max_size
            raise Down::TooLarge, "file is too large (#{current_size/1024/1024}MB, max is #{max_size/1024/1024}MB)"
          end
          progress_proc.call(current_size) if progress_proc
        },
        redirect: false,
      }

      # Handle basic authentication in the :proxy option.
      if options[:proxy]
        proxy    = URI(options.delete(:proxy))
        user     = proxy.user
        password = proxy.password

        if user || password
          proxy.user     = nil
          proxy.password = nil

          open_uri_options[:proxy_http_basic_authentication] = [proxy.to_s, user, password]
        else
          open_uri_options[:proxy] = proxy.to_s
        end
      end

      open_uri_options.merge!(options)
      open_uri_options.merge!(headers)

      uri = ensure_uri(normalize_uri(url, uri_normalizer: uri_normalizer))

      # Handle basic authentication in the remote URL.
      if uri.user || uri.password
        open_uri_options[:http_basic_authentication] ||= [uri.user, uri.password]
        uri.user = nil
        uri.password = nil
      end

      open_uri_file = open_uri(uri, open_uri_options, follows_remaining: max_redirects)

      # Handle the fact that open-uri returns StringIOs for small files.
      extname = extension ? ".#{extension}" : File.extname(open_uri_file.base_uri.path)
      tempfile = ensure_tempfile(open_uri_file, extname)
      OpenURI::Meta.init tempfile, open_uri_file # add back open-uri methods
      tempfile.extend Down::NetHttp::DownloadedFile

      download_result(tempfile, destination)
    end

    # Starts retrieving the remote file using Net::HTTP and returns an IO-like
    # object which downloads the response body on-demand.
    def open(url, *args, **options)
      options = merge_options(@options, *args, **options)

      max_redirects  = options.delete(:max_redirects)
      uri_normalizer = options.delete(:uri_normalizer)

      uri = ensure_uri(normalize_uri(url, uri_normalizer: uri_normalizer))

      # Create a Fiber that halts when response headers are received.
      request = Fiber.new do
        net_http_request(uri, options, follows_remaining: max_redirects) do |response|
          Fiber.yield response
        end
      end

      response = request.resume

      response_error!(response) unless response.is_a?(Net::HTTPSuccess)

      # Build an IO-like object that will retrieve response body on-demand.
      Down::ChunkedIO.new(
        chunks:     enum_for(:stream_body, response),
        size:       response["Content-Length"] && response["Content-Length"].to_i,
        encoding:   response.type_params["charset"],
        rewindable: options.fetch(:rewindable, true),
        on_close:   -> { request.resume }, # close HTTP connnection
        data: {
          status:   response.code.to_i,
          headers:  normalize_headers(response.each_header),
          response: response,
        },
      )
    end

    private

    # Calls open-uri's URI::HTTP#open method. Additionally handles redirects.
    def open_uri(uri, options, follows_remaining:)
      uri.open(options)
    rescue OpenURI::HTTPRedirect => exception
      raise Down::TooManyRedirects, "too many redirects" if follows_remaining == 0

      # fail if redirect URI scheme is not http or https
      begin
        uri = ensure_uri(exception.uri)
      rescue Down::InvalidUrl
        response = rebuild_response_from_open_uri_exception(exception)

        raise ResponseError.new("Invalid Redirect URI: #{exception.uri}", response: response)
      end

      # forward cookies on the redirect
      if !exception.io.meta["set-cookie"].to_s.empty?
        options["Cookie"] ||= ''
        # Add new cookies avoiding duplication
        new_cookies = exception.io.meta["set-cookie"].to_s.split(';').map(&:strip)
        old_cookies = options["Cookie"].split(';')
        options["Cookie"] = (old_cookies | new_cookies).join(';')
      end

      follows_remaining -= 1
      retry
    rescue OpenURI::HTTPError => exception
      response = rebuild_response_from_open_uri_exception(exception)

      # open-uri attempts to parse the redirect URI, so we re-raise that exception
      if exception.message.include?("(Invalid Location URI)")
        raise ResponseError.new("Invalid Redirect URI: #{response["Location"]}", response: response)
      end

      response_error!(response)
    rescue => exception
      request_error!(exception)
    end

    # Converts the given IO into a Tempfile if it isn't one already (open-uri
    # returns a StringIO when there is less than 10KB of content), and gives
    # it the specified file extension.
    def ensure_tempfile(io, extension)
      tempfile = Tempfile.new(["down-net_http", extension], binmode: true)

      if io.is_a?(Tempfile)
        # Windows requires file descriptors to be closed before files are moved
        io.close
        tempfile.close
        FileUtils.mv io.path, tempfile.path
      else
        IO.copy_stream(io, tempfile)
        io.close
      end

      tempfile.open
      tempfile
    end

    # Makes a Net::HTTP request and follows redirects.
    def net_http_request(uri, options, follows_remaining:, &block)
      http, request = create_net_http(uri, options)

      begin
        response = http.start do
          http.request(request) do |resp|
            unless resp.is_a?(Net::HTTPRedirection)
              yield resp
              # In certain cases the caller wants to download only one portion
              # of the file and close the connection, so we tell Net::HTTP that
              # it shouldn't continue retrieving it.
              resp.instance_variable_set("@read", true)
            end
          end
        end
      rescue => exception
        request_error!(exception)
      end

      if response.is_a?(Net::HTTPNotModified)
        raise Down::NotModified
      elsif response.is_a?(Net::HTTPRedirection)
        raise Down::TooManyRedirects if follows_remaining == 0

        # fail if redirect URI is not a valid http or https URL
        begin
          location = ensure_uri(response["Location"], allow_relative: true)
        rescue Down::InvalidUrl
          raise ResponseError.new("Invalid Redirect URI: #{response["Location"]}", response: response)
        end

        # handle relative redirects
        location = uri + location if location.relative?

        net_http_request(location, options, follows_remaining: follows_remaining - 1, &block)
      end
    end

    # Build a Net::HTTP object for making a request.
    def create_net_http(uri, options)
      http_class = Net::HTTP

      if options[:proxy]
        proxy = URI(options[:proxy])
        http_class = Net::HTTP::Proxy(proxy.hostname, proxy.port, proxy.user, proxy.password)
      end

      http = http_class.new(uri.host, uri.port)

      # Handle SSL parameters (taken from the open-uri implementation).
      if uri.is_a?(URI::HTTPS)
        http.use_ssl = true
        http.verify_mode = options[:ssl_verify_mode] || OpenSSL::SSL::VERIFY_PEER
        store = OpenSSL::X509::Store.new
        if options[:ssl_ca_cert]
          Array(options[:ssl_ca_cert]).each do |cert|
            File.directory?(cert) ? store.add_path(cert) : store.add_file(cert)
          end
        else
          store.set_default_paths
        end
        http.cert_store = store
      end

      http.read_timeout = options[:read_timeout] if options.key?(:read_timeout)
      http.open_timeout = options[:open_timeout] if options.key?(:open_timeout)

      headers = options[:headers].to_h
      headers["Accept-Encoding"] = "" # Net::HTTP's inflater causes FiberErrors

      get = Net::HTTP::Get.new(uri.request_uri, headers)

      user, password = options[:http_basic_authentication] || [uri.user, uri.password]
      get.basic_auth(user, password) if user || password

      [http, get]
    end

    # Yields chunks of the response body to the block.
    def stream_body(response, &block)
      response.read_body(&block)
    rescue => exception
      request_error!(exception)
    end

    # Checks that the url is a valid URI and that its scheme is http or https.
    def ensure_uri(url, allow_relative: false)
      begin
        uri = URI(url)
      rescue URI::InvalidURIError => exception
        raise Down::InvalidUrl, exception.message
      end

      unless allow_relative && uri.relative?
        raise Down::InvalidUrl, "URL scheme needs to be http or https: #{uri}" unless uri.is_a?(URI::HTTP)
      end

      uri
    end

    # Makes sure that the URL is properly encoded.
    def normalize_uri(url, uri_normalizer:)
      URI(url)
    rescue URI::InvalidURIError
      uri_normalizer.call(url)
    end

    # When open-uri raises an exception, it doesn't expose the response object.
    # Fortunately, the exception object holds response data that can be used to
    # rebuild the Net::HTTP response object.
    def rebuild_response_from_open_uri_exception(exception)
      code, message = exception.io.status

      response_class = Net::HTTPResponse::CODE_TO_OBJ.fetch(code) do |c|
        Net::HTTPResponse::CODE_CLASS_TO_OBJ.fetch(c[0]) do
          Net::HTTPUnknownResponse
        end
      end
      response       = response_class.new(nil, code, message)

      exception.io.metas.each do |name, values|
        values.each { |value| response.add_field(name, value) }
      end

      response
    end

    # Raises non-sucessful response as a Down::ResponseError.
    def response_error!(response)
      code    = response.code.to_i
      message = response.message.split(" ").map(&:capitalize).join(" ")

      args = ["#{code} #{message}", response]

      case response.code.to_i
      when 404      then raise Down::NotFound.new(*args)
      when 400..499 then raise Down::ClientError.new(*args)
      when 500..599 then raise Down::ServerError.new(*args)
      else               raise Down::ResponseError.new(*args)
      end
    end

    # Re-raise Net::HTTP exceptions as Down::Error exceptions.
    def request_error!(exception)
      case exception
      when Net::OpenTimeout
        raise Down::TimeoutError, "timed out waiting for connection to open"
      when Net::ReadTimeout
        raise Down::TimeoutError, "timed out while reading data"
      when EOFError, IOError, SocketError, SystemCallError
        raise Down::ConnectionError, exception.message
      when OpenSSL::SSL::SSLError
        raise Down::SSLError, exception.message
      else
        raise exception
      end
    end

    # Merge default and ad-hoc options, merging nested headers.
    def merge_options(options, headers = {}, **new_options)
      # Deprecate passing headers as top-level options, taking into account
      # that Ruby 2.7+ accepts kwargs with string keys.
      if headers.any?
        warn %([Down::NetHttp] Passing headers as top-level options has been deprecated, use the :headers option instead, e.g: `Down::NetHttp.download(headers: { "Key" => "Value", ... }, ...)`)
        new_options[:headers] = headers
      elsif new_options.any? { |key, value| key.is_a?(String) }
        warn %([Down::NetHttp] Passing headers as top-level options has been deprecated, use the :headers option instead, e.g: `Down::NetHttp.download(headers: { "Key" => "Value", ... }, ...)`)
        new_options[:headers] = new_options.select { |key, value| key.is_a?(String) }
        new_options.reject! { |key, value| key.is_a?(String) }
      end

      options.merge(new_options) do |key, value1, value2|
        key == :headers ? value1.merge(value2) : value2
      end
    end

    # Defines some additional attributes for the returned Tempfile (on top of what
    # OpenURI::Meta already defines).
    module DownloadedFile
      def original_filename
        Utils.filename_from_content_disposition(meta["content-disposition"]) ||
        Utils.filename_from_path(base_uri.path)
      end

      def content_type
        super unless meta["content-type"].to_s.empty?
      end
    end
  end
end
