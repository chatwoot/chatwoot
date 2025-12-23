# frozen_string_literal: true

module Rack
  # Rack::Headers is a Hash subclass that downcases all keys.  It's designed
  # to be used by rack applications that don't implement the Rack 3 SPEC
  # (by using non-lowercase response header keys), automatically handling
  # the downcasing of keys.
  class Headers < Hash
    KNOWN_HEADERS = {}
    %w(
      Accept-CH
      Accept-Patch
      Accept-Ranges
      Access-Control-Allow-Credentials
      Access-Control-Allow-Headers
      Access-Control-Allow-Methods
      Access-Control-Allow-Origin
      Access-Control-Expose-Headers
      Access-Control-Max-Age
      Age
      Allow
      Alt-Svc
      Cache-Control
      Connection
      Content-Disposition
      Content-Encoding
      Content-Language
      Content-Length
      Content-Location
      Content-MD5
      Content-Range
      Content-Security-Policy
      Content-Security-Policy-Report-Only
      Content-Type
      Date
      Delta-Base
      ETag
      Expect-CT
      Expires
      Feature-Policy
      IM
      Last-Modified
      Link
      Location
      NEL
      P3P
      Permissions-Policy
      Pragma
      Preference-Applied
      Proxy-Authenticate
      Public-Key-Pins
      Referrer-Policy
      Refresh
      Report-To
      Retry-After
      Server
      Set-Cookie
      Status
      Strict-Transport-Security
      Timing-Allow-Origin
      Tk
      Trailer
      Transfer-Encoding
      Upgrade
      Vary
      Via
      WWW-Authenticate
      Warning
      X-Cascade
      X-Content-Duration
      X-Content-Security-Policy
      X-Content-Type-Options
      X-Correlation-ID
      X-Correlation-Id
      X-Download-Options
      X-Frame-Options
      X-Permitted-Cross-Domain-Policies
      X-Powered-By
      X-Redirect-By
      X-Request-ID
      X-Request-Id
      X-Runtime
      X-UA-Compatible
      X-WebKit-CS
      X-XSS-Protection
    ).each do |str|
      downcased = str.downcase.freeze
      KNOWN_HEADERS[str] = KNOWN_HEADERS[downcased] = downcased
    end

    def self.[](*items)
      if items.length % 2 != 0
        if items.length == 1 && items.first.is_a?(Hash)
          new.merge!(items.first)
        else
          raise ArgumentError, "odd number of arguments for Rack::Headers"
        end
      else
        hash = new
        loop do
          break if items.length == 0
          key = items.shift
          value = items.shift
          hash[key] = value
        end
        hash
      end
    end

    def [](key)
      super(downcase_key(key))
    end

    def []=(key, value)
      super(KNOWN_HEADERS[key] || key.downcase.freeze, value)
    end
    alias store []=

    def assoc(key)
      super(downcase_key(key))
    end

    def compare_by_identity
      raise TypeError, "Rack::Headers cannot compare by identity, use regular Hash"
    end

    def delete(key)
      super(downcase_key(key))
    end

    def dig(key, *a)
      super(downcase_key(key), *a)
    end

    def fetch(key, *default, &block)
      key = downcase_key(key)
      super
    end

    def fetch_values(*a)
      super(*a.map!{|key| downcase_key(key)})
    end

    def has_key?(key)
      super(downcase_key(key))
    end
    alias include? has_key?
    alias key? has_key?
    alias member? has_key?

    def invert
      hash = self.class.new
      each{|key, value| hash[value] = key}
      hash
    end

    def merge(hash, &block)
      dup.merge!(hash, &block)
    end

    def reject(&block)
      hash = dup
      hash.reject!(&block)
      hash
    end

    def replace(hash)
      clear
      update(hash)
    end

    def select(&block)
      hash = dup
      hash.select!(&block)
      hash
    end

    def to_proc
      lambda{|x| self[x]}
    end

    def transform_values(&block)
      dup.transform_values!(&block)
    end

    def update(hash, &block)
      hash.each do |key, value|
        self[key] = if block_given? && include?(key)
          block.call(key, self[key], value)
        else
          value
        end
      end
      self
    end
    alias merge! update

    def values_at(*keys)
      keys.map{|key| self[key]}
    end

    # :nocov:
    if RUBY_VERSION >= '2.5'
    # :nocov:
      def slice(*a)
        h = self.class.new
        a.each{|k| h[k] = self[k] if has_key?(k)}
        h
      end

      def transform_keys(&block)
        dup.transform_keys!(&block)
      end

      def transform_keys!
        hash = self.class.new
        each do |k, v|
          hash[yield k] = v
        end
        replace(hash)
      end
    end

    # :nocov:
    if RUBY_VERSION >= '3.0'
    # :nocov:
      def except(*a)
        super(*a.map!{|key| downcase_key(key)})
      end
    end

    private

    def downcase_key(key)
      key.is_a?(String) ? KNOWN_HEADERS[key] || key.downcase : key
    end
  end
end
