module ScoutApm
  module Instruments
    class HTTP
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
        if defined?(::HTTP) && defined?(::HTTP::Client)
          @installed = true

          logger.info "Instrumenting HTTP::Client. Prepend: #{prepend}"

          if prepend
            ::HTTP::Client.send(:include, ScoutApm::Tracer)
            ::HTTP::Client.send(:prepend, HTTPInstrumentationPrepend)
          else
            ::HTTP::Client.class_eval do
              include ScoutApm::Tracer

              def request_with_scout_instruments(verb, uri, opts = {})
                self.class.instrument("HTTP", verb, :ignore_children => true, :desc => request_scout_description(verb, uri)) do
                  request_without_scout_instruments(verb, uri, opts)
                end
              end

              def request_scout_description(verb, uri)
                max_length = ScoutApm::Agent.instance.context.config.value('instrument_http_url_length')
                (String(uri).split('?').first)[0..(max_length - 1)]
              rescue
                ""
              end

              alias request_without_scout_instruments request
              alias request request_with_scout_instruments
            end
          end
        end
      end
    end

    module HTTPInstrumentationPrepend
      def request(verb, uri, opts = {})
        self.class.instrument("HTTP", verb, :ignore_children => true, :desc => request_scout_description(verb, uri)) do
          super(verb, uri, opts)
        end
      end

      def request_scout_description(verb, uri)
        max_length = ScoutApm::Agent.instance.context.config.value('instrument_http_url_length')
        (String(uri).split('?').first)[0..(max_length - 1)]
      rescue
        ""
      end
    end
  end
end
