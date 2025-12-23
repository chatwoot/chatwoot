# frozen_string_literal: true

require_relative 'constants'
require_relative 'utils'
require_relative 'body_proxy'

module Rack

  # = Sendfile
  #
  # The Sendfile middleware intercepts responses whose body is being
  # served from a file and replaces it with a server specific x-sendfile
  # header. The web server is then responsible for writing the file contents
  # to the client. This can dramatically reduce the amount of work required
  # by the Ruby backend and takes advantage of the web server's optimized file
  # delivery code.
  #
  # In order to take advantage of this middleware, the response body must
  # respond to +to_path+ and the request must include an `x-sendfile-type`
  # header. Rack::Files and other components implement +to_path+ so there's
  # rarely anything you need to do in your application. The `x-sendfile-type`
  # header is typically set in your web servers configuration. The following
  # sections attempt to document
  #
  # === Nginx
  #
  # Nginx supports the `x-accel-redirect` header. This is similar to `x-sendfile`
  # but requires parts of the filesystem to be mapped into a private URL
  # hierarchy.
  #
  # The following example shows the Nginx configuration required to create
  # a private "/files/" area, enable `x-accel-redirect`, and pass the special
  # `x-accel-mapping` header to the backend:
  #
  #   location ~ /files/(.*) {
  #     internal;
  #     alias /var/www/$1;
  #   }
  #
  #   location / {
  #     proxy_redirect     off;
  #
  #     proxy_set_header   Host                $host;
  #     proxy_set_header   X-Real-IP           $remote_addr;
  #     proxy_set_header   X-Forwarded-For     $proxy_add_x_forwarded_for;
  #
  #     proxy_set_header   x-accel-mapping     /var/www/=/files/;
  #
  #     proxy_pass         http://127.0.0.1:8080/;
  #   }
  #
  # The `x-accel-mapping` header should specify the location on the file system,
  # followed by an equals sign (=), followed name of the private URL pattern
  # that it maps to. The middleware performs a simple substitution on the
  # resulting path.
  #
  # To enable `x-accel-redirect`, you must configure the middleware explicitly:
  #
  #   use Rack::Sendfile, "x-accel-redirect"
  #
  # For security reasons, the `x-sendfile-type` header from requests is ignored.
  # The sendfile variation must be set via the middleware constructor.
  #
  # See Also: https://www.nginx.com/resources/wiki/start/topics/examples/xsendfile
  #
  # === lighttpd
  #
  # Lighttpd has supported some variation of the `x-sendfile` header for some
  # time, although only recent version support `x-sendfile` in a reverse proxy
  # configuration.
  #
  #   $HTTP["host"] == "example.com" {
  #      proxy-core.protocol = "http"
  #      proxy-core.balancer = "round-robin"
  #      proxy-core.backends = (
  #        "127.0.0.1:8000",
  #        "127.0.0.1:8001",
  #        ...
  #      )
  #
  #      proxy-core.allow-x-sendfile = "enable"
  #      proxy-core.rewrite-request = (
  #        "x-sendfile-type" => (".*" => "x-sendfile")
  #      )
  #    }
  #
  # See Also: http://redmine.lighttpd.net/wiki/lighttpd/Docs:ModProxyCore
  #
  # === Apache
  #
  # `x-sendfile` is supported under Apache 2.x using a separate module:
  #
  # https://tn123.org/mod_xsendfile/
  #
  # Once the module is compiled and installed, you can enable it using
  # XSendFile config directive:
  #
  #   RequestHeader Set x-sendfile-type x-sendfile
  #   ProxyPassReverse / http://localhost:8001/
  #   XSendFile on
  #
  # === Mapping parameter
  #
  # The third parameter allows for an overriding extension of the
  # `x-accel-mapping` header. Mappings should be provided in tuples of internal to
  # external. The internal values may contain regular expression syntax, they
  # will be matched with case indifference.
  #
  # When `x-accel-redirect` is explicitly enabled via the variation parameter,
  # and no application-level mappings are provided, the middleware will read
  # the `x-accel-mapping` header from the proxy. This allows nginx to control
  # the path mapping without requiring application-level configuration.
  #
  # === Security
  #
  # For security reasons, the `x-sendfile-type` header from HTTP requests is
  # ignored. The sendfile variation must be explicitly configured via the
  # middleware constructor to prevent information disclosure vulnerabilities
  # where attackers could bypass proxy restrictions.

  class Sendfile
    def initialize(app, variation = nil, mappings = [])
      @app = app
      @variation = variation
      @mappings = mappings.map do |internal, external|
        [/\A#{internal}/i, external]
      end
    end

    def call(env)
      _, headers, body = response = @app.call(env)

      if body.respond_to?(:to_path)
        case type = variation(env)
        when /x-accel-redirect/i
          path = ::File.expand_path(body.to_path)
          if url = map_accel_path(env, path)
            headers[CONTENT_LENGTH] = '0'
            # '?' must be percent-encoded because it is not query string but a part of path
            headers[type.downcase] = ::Rack::Utils.escape_path(url).gsub('?', '%3F')
            obody = body
            response[2] = Rack::BodyProxy.new([]) do
              obody.close if obody.respond_to?(:close)
            end
          else
            env[RACK_ERRORS].puts "x-accel-mapping header missing"
          end
        when /x-sendfile|x-lighttpd-send-file/i
          path = ::File.expand_path(body.to_path)
          headers[CONTENT_LENGTH] = '0'
          headers[type.downcase] = path
          obody = body
          response[2] = Rack::BodyProxy.new([]) do
            obody.close if obody.respond_to?(:close)
          end
        when '', nil
        else
          env[RACK_ERRORS].puts "Unknown x-sendfile variation: #{type.inspect}"
        end
      end
      response
    end

    private

    def variation(env)
      # Note: HTTP_X_SENDFILE_TYPE is intentionally NOT read for security reasons.
      # Attackers could use this header to enable x-accel-redirect and bypass proxy restrictions.
      @variation || env['sendfile.type']
    end

    def x_accel_mapping(env)
      # Only allow header when:
      # 1. `x-accel-redirect` is explicitly enabled via constructor.
      # 2. No application-level mappings are configured.
      return nil unless @variation =~ /x-accel-redirect/i
      return nil if @mappings.any?
      
      env['HTTP_X_ACCEL_MAPPING']
    end

    def map_accel_path(env, path)
      if mapping = @mappings.find { |internal, _| internal =~ path }
        return path.sub(*mapping)
      elsif mapping = x_accel_mapping(env)
        # Safe to use header: explicit config + no app mappings:
        mapping.split(',').map(&:strip).each do |m|
          internal, external = m.split('=', 2).map(&:strip)
          new_path = path.sub(/\A#{internal}/i, external)
          return new_path unless path == new_path
        end

        return path
      end
    end
  end
end
