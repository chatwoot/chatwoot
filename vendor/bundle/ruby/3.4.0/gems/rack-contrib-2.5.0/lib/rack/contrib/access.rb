# frozen_string_literal: true

require "ipaddr"

module Rack

  ##
  # Rack middleware for limiting access based on IP address
  #
  #
  # === Options:
  #
  #   path => ipmasks      ipmasks: Array of remote addresses which are allowed to access
  #
  # === Examples:
  #
  #  use Rack::Access, '/backend' => [ '127.0.0.1',  '192.168.1.0/24' ]
  #
  #

  class Access

    attr_reader :options

    def initialize(app, options = {})
      @app = app
      mapping = options.empty? ? {"/" => ["127.0.0.1"]} : options
      @mapping = remap(mapping)
    end

    def remap(mapping)
      mapping.map { |location, ipmasks|
        if location =~ %r{\Ahttps?://(.*?)(/.*)}
          host, location = $1, $2
        else
          host = nil
        end

        unless location[0] == ?/
          raise ArgumentError, "paths need to start with /"
        end
        location = location.chomp('/')
        match = Regexp.new("^#{Regexp.quote(location).gsub('/', '/+')}(.*)", Regexp::NOENCODING)

        ipmasks.collect! do |ipmask|
          ipmask.is_a?(IPAddr) ? ipmask : IPAddr.new(ipmask)
        end
        [host, location, match, ipmasks]
      }.sort_by { |(h, l, m, a)| [h ? -h.size : (-1.0 / 0.0), -l.size] }  # Longest path first
    end

    def call(env)
      request = Request.new(env)
      ipmasks = ipmasks_for_path(env)
      return forbidden! unless ip_authorized?(request, ipmasks)
      status, headers, body = @app.call(env)
      [status, headers, body]
    end

    def ipmasks_for_path(env)
      path = env["PATH_INFO"].to_s
      hHost, sName, sPort = env.values_at('HTTP_HOST','SERVER_NAME','SERVER_PORT')
      @mapping.each do |host, location, match, ipmasks|
        next unless (hHost == host || sName == host \
            || (host.nil? && (hHost == sName || hHost == sName+':'+sPort)))
        next unless path =~ match && rest = $1
        next unless rest.empty? || rest[0] == ?/

        return ipmasks
      end
      nil
    end

    def forbidden!
      [403, { 'content-type' => 'text/html', 'content-length' => '0' }, []]
    end

    def ip_authorized?(request, ipmasks)
      return true if ipmasks.nil?

      ipmasks.any? do |ip_mask|
        ip_mask.include?(IPAddr.new(request.ip))
      end
    end

  end
end
