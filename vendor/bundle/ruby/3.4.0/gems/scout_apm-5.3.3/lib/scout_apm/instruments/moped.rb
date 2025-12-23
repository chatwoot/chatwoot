module ScoutApm
  module Instruments
    class Moped
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
        if defined?(::Moped)
          @installed = true

          logger.info "Instrumenting Moped. Prepend: #{prepend}"

          if prepend
            ::Moped::Node.send(:include, ScoutApm::Tracer)
            ::Moped::Node.send(:prepend, MopedInstrumentationPrepend)
          else
            ::Moped::Node.class_eval do
              include ScoutApm::Tracer

              def process_with_scout_instruments(operation, &callback)
                if operation.respond_to?(:collection)
                  collection = operation.collection
                  name = "Process/#{collection}/#{operation.class.to_s.split('::').last}"
                  self.class.instrument("MongoDB", name, :annotate_layer => { :query => scout_sanitize_log(operation.log_inspect) }) do
                    process_without_scout_instruments(operation, &callback)
                  end
                end
              end
              alias_method :process_without_scout_instruments, :process
              alias_method :process, :process_with_scout_instruments

              # replaces values w/ ?
              def scout_sanitize_log(log)
                return nil if log.length > 1000 # safeguard - don't sanitize large SQL statements
                log.gsub(/(=>")((?:[^"]|"")*)"/) do
                  $1 + '?' + '"'
                end
              end
            end
          end
        end
      end

    end

    module MopedInstrumentationPrepend
      def process(operation, &callback)
        if operation.respond_to?(:collection)
          collection = operation.collection
          name = "Process/#{collection}/#{operation.class.to_s.split('::').last}"
          self.class.instrument("MongoDB", name, :annotate_layer => { :query => scout_sanitize_log(operation.log_inspect) }) do
            super(operation, &callback)
          end
        end
      end

      # replaces values w/ ?
      def scout_sanitize_log(log)
        return nil if log.length > 1000 # safeguard - don't sanitize large SQL statements
        log.gsub(/(=>")((?:[^"]|"")*)"/) do
          $1 + '?' + '"'
        end
      end
    end
  end
end

