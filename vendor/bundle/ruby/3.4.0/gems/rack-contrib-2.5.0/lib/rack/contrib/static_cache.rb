# frozen_string_literal: true

require 'time'

module Rack

  #
  # The Rack::StaticCache middleware automatically adds, removes and modifies
  # stuffs in response headers to facilitiate client and proxy caching for static files
  # that minimizes http requests and improves overall load times for second time visitors.
  #
  # Once a static content is stored in a client/proxy the only way to enforce the browser
  # to fetch the latest content and ignore the cache is to rename the static file.
  #
  # Alternatively, we can add a version number into the URL to the content to bypass
  # the caches. Rack::StaticCache by default handles version numbers in the filename.
  # As an example,
  # http://yoursite.com/images/test-1.0.0.png and http://yoursite.com/images/test-2.0.0.png
  # both reffers to the same image file http://yoursite.com/images/test.png
  #
  # Another way to bypass the cache is adding the version number in a field-value pair in the
  # URL query string. As an example, http://yoursite.com/images/test.png?v=1.0.0
  # In that case, set the option :versioning to false to avoid unnecessary regexp calculations.
  #
  # It's better to keep the current version number in some config file and use it in every static
  # content's URL. So each time we modify our static contents, we just have to change the version
  # number to enforce the browser to fetch the latest content.
  #
  # You can use Rack::Deflater along with Rack::StaticCache for further improvements in page loading time.
  #
  # If you'd like to use a non-standard version identifier in your URLs, you
  # can set the regex to remove with the `:version_regex` option.  If you
  # want to capture something after the regex (such as file extensions), you
  # should capture that as `\1`.  All other captured subexpressions will be
  # discarded.  You may find the `?:` capture modifier helpful.
  #
  # Examples:
  #     use Rack::StaticCache, :urls => ["/images", "/css", "/js", "/documents*"], :root => "statics"
  #     will serve all requests beginning with /images, /css or /js from the
  #     directory "statics/images",  "statics/css",  "statics/js".
  #     All the files from these directories will have modified headers to enable client/proxy caching,
  #     except the files from the directory "documents". Append a * (star) at the end of the pattern
  #     if you want to disable caching for any pattern . In that case, plain static contents will be served with
  #     default headers.
  #
  #     use Rack::StaticCache, :urls => ["/images"], :duration => 2, :versioning => false
  #     will serve all requests beginning with /images under the current directory (default for the option :root
  #     is current directory). All the contents served will have cache expiration duration set to 2 years in headers
  #     (default for :duration is 1 year), and StaticCache will not compute any versioning logics (default for
  #     :versioning is true)
  #


  class StaticCache
    HEADERS_KLASS = Rack.release < "3" ? Utils::HeaderHash : Headers
    private_constant :HEADERS_KLASS

    def initialize(app, options={})
      @app = app
      @urls = options[:urls]
      @no_cache = {}
      @urls.collect! do |url|
        if url  =~ /\*$/
          url_prefix = url.sub(/\*$/, '')
          @no_cache[url_prefix] = 1
          url_prefix
        else
          url
        end
      end
      root = options[:root] || Dir.pwd
      @file_server = Rack::Files.new(root)
      @cache_duration = options[:duration] || 1
      @versioning_enabled = options.fetch(:versioning, true)
      if @versioning_enabled
        @version_regex = options.fetch(:version_regex, /-[\d.]+([.][a-zA-Z][\w]+)?$/)
      end
      @duration_in_seconds = self.duration_in_seconds
    end

    def call(env)
      path = env["PATH_INFO"]
      url = @urls.detect{ |u| path.index(u) == 0 }
      if url.nil?
        @app.call(env)
      else
        if @versioning_enabled
          path.sub!(@version_regex, '\1')
        end

        status, headers, body = @file_server.call(env)
        headers = HEADERS_KLASS.new.merge(headers)

        if @no_cache[url].nil?
          headers['Cache-Control'] ="max-age=#{@duration_in_seconds}, public"
          headers['Expires'] = duration_in_words
        end
        headers['Date'] = Time.now.httpdate
        [status, headers, body]
      end
    end

    def duration_in_words
      (Time.now.utc + self.duration_in_seconds).httpdate
    end

    def duration_in_seconds
      (60 * 60 * 24 * 365 * @cache_duration).to_i
    end
  end
end
