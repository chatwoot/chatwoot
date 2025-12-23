# frozen_string_literal: false

module ScoutApm
  module Instruments
    class Elasticsearch
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
        if defined?(::Elasticsearch) &&
            defined?(::Elasticsearch::Transport) &&
            defined?(::Elasticsearch::Transport::Client)

          @installed = true

          logger.info "Instrumenting Elasticsearch. Prepend: #{prepend}"

          if prepend
            ::Elasticsearch::Transport::Client.send(:include, ScoutApm::Tracer)
            ::Elasticsearch::Transport::Client.send(:prepend, ElasticsearchTransportClientInstrumentationPrepend)
          else
            ::Elasticsearch::Transport::Client.class_eval do
              include ScoutApm::Tracer

              def perform_request_with_scout_instruments(*args, &block)
                name = _sanitize_name(args[1])

                self.class.instrument("Elasticsearch", name, :ignore_children => true) do
                  perform_request_without_scout_instruments(*args, &block)
                end
              end

              alias_method :perform_request_without_scout_instruments, :perform_request
              alias_method :perform_request, :perform_request_with_scout_instruments

              def _sanitize_name(name)
                name = name.split("/").last.gsub(/^_/, '')
                allowed_names = ["bench",
                                "bulk",
                                "count",
                                "exists",
                                "explain",
                                "field_stats",
                                "health",
                                "mget",
                                "mlt",
                                "mpercolate",
                                "msearch",
                                "mtermvectors",
                                "percolate",
                                "query",
                                "scroll",
                                "search_shards",
                                "source",
                                "suggest",
                                "template",
                                "termvectors",
                                "update",
                                "search", ]

                if allowed_names.include?(name)
                  name
                else
                  "Unknown"
                end
              rescue
                "Unknown"
              end
            end
          end
        end
      end
    end

    module ElasticsearchTransportClientInstrumentationPrepend
      def perform_request(*args, &block)
        name = _sanitize_name(args[1])

        self.class.instrument("Elasticsearch", name, :ignore_children => true) do
          super(*args, &block)
        end
      end

      def _sanitize_name(name)
        name = name.split("/").last.gsub(/^_/, '')
        allowed_names = ["bench",
                        "bulk",
                        "count",
                        "exists",
                        "explain",
                        "field_stats",
                        "health",
                        "mget",
                        "mlt",
                        "mpercolate",
                        "msearch",
                        "mtermvectors",
                        "percolate",
                        "query",
                        "scroll",
                        "search_shards",
                        "source",
                        "suggest",
                        "template",
                        "termvectors",
                        "update",
                        "search", ]

        if allowed_names.include?(name)
          name
        else
          "Unknown"
        end
      rescue
        "Unknown"
      end
    end
  end
end

