# frozen_string_literal: true

require "uri"

class RedisClient
  class URLConfig
    attr_reader :url, :uri

    def initialize(url)
      @url = url
      @uri = URI(url)
      @unix = false
      @ssl = false
      case uri.scheme
      when "redis"
        # expected
      when "rediss"
        @ssl = true
      when "unix", nil
        @unix = true
      else
        raise ArgumentError, "Unknown URL scheme: #{url.inspect}"
      end
    end

    def ssl?
      @ssl
    end

    def db
      unless @unix
        db_path = uri.path&.delete_prefix("/")
        return Integer(db_path) if db_path && !db_path.empty?
      end

      unless uri.query.nil? || uri.query.empty?
        _, db_query = URI.decode_www_form(uri.query).find do |key, _|
          key == "db"
        end
        return Integer(db_query) if db_query && !db_query.empty?
      end
    end

    def username
      uri.user if uri.password && !uri.user.empty?
    end

    def password
      if uri.user && !uri.password
        URI.decode_www_form_component(uri.user)
      elsif uri.user && uri.password
        URI.decode_www_form_component(uri.password)
      end
    end

    def host
      return if uri.host.nil? || uri.host.empty?

      uri.host.sub(/\A\[(.*)\]\z/, '\1')
    end

    def path
      if @unix
        File.join(*[uri.host, uri.path].compact)
      end
    end

    def port
      return unless uri.port

      Integer(uri.port)
    end
  end
end
