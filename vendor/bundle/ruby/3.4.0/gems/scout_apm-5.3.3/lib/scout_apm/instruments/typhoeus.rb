module ScoutApm
  module Instruments
    class Typhoeus
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
        if defined?(::Typhoeus)
          @installed = true

          logger.info "Instrumenting Typhoeus"

          ::Typhoeus::Request.send(:prepend, TyphoeusInstrumentation)
          ::Typhoeus::Hydra.send(:prepend, TyphoeusHydraInstrumentation)
        end
      end

      module TyphoeusHydraInstrumentation
        def run(*args, &block)
          layer = ScoutApm::Layer.new("HTTP", "Hydra")
          layer.desc = scout_desc

          req = ScoutApm::RequestManager.lookup
          req.start_layer(layer)

          begin
            super(*args, &block)
          ensure
            req.stop_layer
          end
        end

        def scout_desc
          "#{self.queued_requests.count} requests"
        rescue
          ""
        end
      end

      module TyphoeusInstrumentation
        def run(*args, &block)
          layer = ScoutApm::Layer.new("HTTP", scout_request_verb)
          layer.desc = scout_desc(scout_request_verb, scout_request_url)

          req = ScoutApm::RequestManager.lookup
          req.start_layer(layer)

          begin
            super(*args, &block)
          ensure
            req.stop_layer
          end
        end

        def scout_desc(verb, uri)
          max_length = ScoutApm::Agent.instance.context.config.value('instrument_http_url_length')
          (String(uri).split('?').first)[0..(max_length - 1)]
        rescue
          ""
        end

        def scout_request_url
          self.url
        rescue
          ""
        end

        def scout_request_verb
          self.options[:method].to_s
        rescue
          ""
        end

      end

    end
  end
end
