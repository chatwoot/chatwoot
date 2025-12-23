# frozen_string_literal: true

module Rack

  ##
  # This middleware is like Rack::ConditionalGet except that it does
  # not have to go down the rack stack and build the resource to check
  # the modification date or the ETag.
  #
  # Instead it makes the assumption that only non-reading requests can
  # potentially change the content, meaning any request which is not
  # GET or HEAD. Each time you make one of these request, the date is cached
  # and any resource is considered identical until the next non-reading request.
  #
  # Basically you use it this way:
  #
  # ``` ruby
  # use Rack::LazyConditionalGet
  # ```
  #
  # Although if you have multiple instances, it is better to use something like
  # memcached. An argument can be passed to give the cache object. By default
  # it is just a Hash. But it can take other objects, including objects which
  # respond to `:get` and `:set`. Here is how you would use it with Dalli.
  #
  # ``` Ruby
  # dalli_client = Dalli::Client.new
  # use Rack::LazyConditionalGet, dalli_client
  # ```
  #
  # By default, the middleware only delegates to Rack::ConditionalGet to avoid
  # any unwanted behaviour. You have to set a header to any resource which you
  # want to be cached. And it will be cached until the next "potential update"
  # of your site, that is whenever the next POST/PUT/PATCH/DELETE request
  # is received.
  #
  # The header is `Rack-Lazy-Conditional-Get`. You have to set it to 'yes'
  # if you want the middleware to set `Last-Modified` for you.
  #
  # Bear in mind that if you set `Last-Modified` as well, the middleware will
  # not change it.
  #
  # Regarding the POST/PUT/PATCH/DELETE... requests, they will always reset your
  # global modification date. But if you have one of these request and you
  # know for sure that it does not modify the cached content, you can set the
  # `Rack-Lazy-Conditional-Get` on response to `skip`. This will not update the
  # global modification date.
  #
  # NOTE: This will not work properly in a multi-threaded environment with
  # default cache object. A provided cache object should ensure thread-safety
  # of the `get`/`set`/`[]`/`[]=` methods.

  class LazyConditionalGet

    KEY = 'global_last_modified'.freeze
    READ_METHODS = ['GET','HEAD']

    def self.new(*)
      # This code automatically uses `Rack::ConditionalGet` before
      # our middleware. It is equivalent to:
      #
      # ``` ruby
      # use Rack::ConditionalGet
      # use Rack::LazyConditionalGet
      # ```
      ::Rack::ConditionalGet.new(super)
    end

    def initialize app, cache={}
      @app = app
      @cache = cache
      update_cache
    end

    def call env
      if reading? env and fresh? env
        return [304, {'last-modified' => env['HTTP_IF_MODIFIED_SINCE']}, []]
      end

      status, headers, body = @app.call env
      headers = Rack.release < "3" ? Utils::HeaderHash.new(headers) : headers

      update_cache unless (reading?(env) or skipping?(headers))
      headers['last-modified'] = cached_value if stampable? headers
      [status, headers, body]
    end

    private

    def fresh? env
      env['HTTP_IF_MODIFIED_SINCE'] == cached_value
    end

    def reading? env
      READ_METHODS.include?(env['REQUEST_METHOD'])
    end

    def skipping? headers
      headers['rack-lazy-conditional-get'] == 'skip'
    end

    def stampable? headers
      !headers.has_key?('last-modified') and headers['rack-lazy-conditional-get'] == 'yes'
    end

    def update_cache
      stamp = Time.now.httpdate
      if @cache.respond_to?(:set)
        @cache.set(KEY,stamp)
      else
        @cache[KEY] = stamp
      end
    end

    def cached_value
      @cache.respond_to?(:get) ? @cache.get(KEY) : @cache[KEY]
    end

  end

end

