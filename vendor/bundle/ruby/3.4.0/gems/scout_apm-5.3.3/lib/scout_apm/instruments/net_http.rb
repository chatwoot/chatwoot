module ScoutApm
  module Instruments
    class NetHttp
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
        if defined?(::Net) && defined?(::Net::HTTP)
          @installed = true

          logger.info "Instrumenting Net::HTTP. Prepend: #{prepend}"

          if prepend
            ::Net::HTTP.send(:include, ScoutApm::Tracer)
            ::Net::HTTP.send(:prepend, NetHttpInstrumentationPrepend)
          else
            ::Net::HTTP.class_eval do
              include ScoutApm::Tracer

              def request_with_scout_instruments(*args, &block)
                self.class.instrument("HTTP", "request", :ignore_children => true, :desc => request_scout_description(args.first)) do
                  request_without_scout_instruments(*args, &block)
                end
              end

              def request_scout_description(req)
                path = req.path
                path = path.path if path.respond_to?(:path)

                # Protect against a nil address value
                if @address.nil?
                  return "No Address Found"
                end

                max_length = ScoutApm::Agent.instance.context.config.value('instrument_http_url_length')
                (@address + path.split('?').first)[0..(max_length - 1)]
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

    module NetHttpInstrumentationPrepend
      def request(request, *args, &block)
        self.class.instrument("HTTP", "request", :ignore_children => true, :desc => request_scout_description(args.first)) do
          super(request, *args, &block)
        end
      end

      def request_scout_description(req)
        path = req.path
        path = path.path if path.respond_to?(:path)

        # Protect against a nil address value
        if @address.nil?
          return "No Address Found"
        end

        max_length = ScoutApm::Agent.instance.context.config.value('instrument_http_url_length')
        (@address + path.split('?').first)[0..(max_length - 1)]
      rescue
        ""
      end
    end
  end
end
