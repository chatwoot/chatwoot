require 'uri'

# NOTE: This code is copied directly from Redis.
#       Its purpose is to resolve connection information.
#       It exists here only because it doesn't exist in the redis
#       library as a separated module and it allows to avoid
#       instantiating a new Redis::Client for resolving the connection
module Datadog
  module Tracing
    module Contrib
      module Redis
        module Vendor
          class Resolver # :nodoc:
            # Connection DEFAULTS for a Redis::Client are unchanged for
            # the integration supported options.
            # https://github.com/redis/redis-rb/blob/v3.0.0/lib/redis/client.rb#L6-L14
            # https://github.com/redis/redis-rb/blob/v4.1.3/lib/redis/client.rb#L10-L26
            # Since the integration takes in consideration only few attributes, all
            # versions are compatible for :url, :scheme, :host, :port, :db
            DEFAULTS = {
              url: -> { ENV['REDIS_URL'] },
              scheme: 'redis',
              host: '127.0.0.1',
              port: 6379,
              path: nil,
              # :timeout => 5.0,
              password: nil,
              db: 0 # ,
              # :driver => nil,
              # :id => nil,
              # :tcp_keepalive => 0,
              # :reconnect_attempts => 1,
              # :reconnect_delay => 0,
              # :reconnect_delay_max => 0.5,
              # :inherit_socket => false
            }.freeze

            def resolve(options)
              _parse_options(options)
            end

            # rubocop:disable Metrics/AbcSize
            # rubocop:disable Metrics/MethodLength
            # rubocop:disable Metrics/PerceivedComplexity
            #
            # This method is a subset of the implementation provided in v3.0.0
            # https://github.com/redis/redis-rb/blob/v3.0.0/lib/redis/client.rb
            # https://github.com/redis/redis-rb/blob/v4.1.3/lib/redis/client.rb
            #
            # Since it has been backported from the original gem, some linting
            # cops have been disabled
            def _parse_options(options)
              # https://github.com/redis/redis-rb/blob/v4.1.3/lib/redis/client.rb#L404
              # Early return for modern client options
              return options if options[:_parsed]

              defaults = DEFAULTS.dup
              options = options.dup

              defaults.each_key do |key|
                # Fill in defaults if needed
                defaults[key] = defaults[key].call if defaults[key].respond_to?(:call)

                # Symbolize only keys that are needed
                options[key] = options[key.to_s] if options.key?(key.to_s)
              end

              url = options[:url]
              url = defaults[:url] if url.nil?

              # Override defaults from URL if given
              if url
                uri = URI(url)

                case uri.scheme
                when 'unix'
                  defaults[:path] = uri.path
                when 'redis', 'rediss'
                  defaults[:scheme]   = uri.scheme
                  defaults[:host]     = uri.host if uri.host
                  defaults[:port]     = uri.port if uri.port
                  defaults[:password] = CGI.unescape(uri.password) if uri.password
                  defaults[:db]       = uri.path[1..-1].to_i if uri.path
                  defaults[:role] = :master
                else
                  raise ArgumentError, "invalid uri scheme '#{uri.scheme}'"
                end

                # defaults[:ssl] = true if uri.scheme == "rediss"
              end

              # Use default when option is not specified or nil
              defaults.each_key do |key|
                options[key] = defaults[key] if options[key].nil?
              end

              if options[:path]
                # Unix socket
                options[:scheme] = 'unix'
                options.delete(:host)
                options.delete(:port)
              else
                # TCP socket
                options[:host] = options[:host].to_s
                options[:port] = options[:port].to_i
              end

              # Options ignored by the integration
              #
              # if options.has_key?(:timeout)
              #   options[:connect_timeout] ||= options[:timeout]
              #   options[:read_timeout]    ||= options[:timeout]
              #   options[:write_timeout]   ||= options[:timeout]
              # end

              # options[:connect_timeout] = Float(options[:connect_timeout])
              # options[:read_timeout]    = Float(options[:read_timeout])
              # options[:write_timeout]   = Float(options[:write_timeout])

              # options[:reconnect_attempts] = options[:reconnect_attempts].to_i
              # options[:reconnect_delay] = options[:reconnect_delay].to_f
              # options[:reconnect_delay_max] = options[:reconnect_delay_max].to_f

              options[:db] = options[:db].to_i
              # options[:driver] = _parse_driver(options[:driver]) || Connection.drivers.last

              # case options[:tcp_keepalive]
              # when Hash
              #   [:time, :intvl, :probes].each do |key|
              #     unless options[:tcp_keepalive][key].is_a?(Integer)
              #       raise "Expected the #{key.inspect} key in :tcp_keepalive to be an Integer"
              #     end
              #   end

              # when Integer
              #   if options[:tcp_keepalive] >= 60
              #     options[:tcp_keepalive] = {:time => options[:tcp_keepalive] - 20, :intvl => 10, :probes => 2}

              #   elsif options[:tcp_keepalive] >= 30
              #     options[:tcp_keepalive] = {:time => options[:tcp_keepalive] - 10, :intvl => 5, :probes => 2}

              #   elsif options[:tcp_keepalive] >= 5
              #     options[:tcp_keepalive] = {:time => options[:tcp_keepalive] - 2, :intvl => 2, :probes => 1}
              #   end
              # end

              options[:_parsed] = true

              options
            end

            # rubocop:enable Metrics/AbcSize
            # rubocop:enable Metrics/MethodLength
            # rubocop:enable Metrics/PerceivedComplexity
          end
        end
      end
    end
  end
end
