module ScoutApm
  module Instruments
    class Grape
      attr_reader :context

      def initialize(context)
        @context = context
        @installed = false
      end

      def logger
        context.logger
      end

      def installed?
        @installed
      end

      def install(prepend:)
        if defined?(::Grape) && defined?(::Grape::Endpoint)
          @installed = true

          logger.info "Instrumenting Grape::Endpoint"

          ::Grape::Endpoint.class_eval do
            include ScoutApm::Instruments::GrapeEndpointInstruments

            alias run_without_scout_instruments run
            alias run run_with_scout_instruments
          end
        end
      end
    end

    module GrapeEndpointInstruments
      def run_with_scout_instruments(*args)
        request = ::Grape::Request.new(env || args.first)
        req = ScoutApm::RequestManager.lookup

        path = ScoutApm::Agent.instance.context.config.value("uri_reporting") == 'path' ? request.path : request.fullpath
        req.annotate_request(:uri => path)

        # IP Spoofing Protection can throw an exception, just move on w/o remote ip
        req.context.add_user(:ip => request.ip) rescue nil

        req.set_headers(request.headers)

        begin
          name = ["Grape",
                  self.options[:method].first,
                  self.options[:for].to_s,
                  self.namespace.sub(%r{\A/}, ''), # removing leading slashes
                  self.options[:path].first,
          ].compact.map{ |n| n.to_s }.join("/")
        rescue => e
          logger.info("Error getting Grape Endpoint Name. Error: #{e.message}. Options: #{self.options.inspect}")
          name = "Grape/Unknown"
        end

        req.start_layer( ScoutApm::Layer.new("Controller", name) )
        begin
          run_without_scout_instruments(*args)
        rescue
          req.error!
          raise
        ensure
          req.stop_layer
        end
      end
    end
  end
end

