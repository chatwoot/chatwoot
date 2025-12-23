# frozen_string_literal: true

require_relative 'fetcher'
require_relative '../../../distributed/b3_multi'
require_relative '../../../distributed/b3_single'
require_relative '../../../distributed/propagation_policy'
require_relative '../../../distributed/datadog'
require_relative '../../../distributed/none'
require_relative '../../../distributed/propagation'
require_relative '../../../distributed/trace_context'

module Datadog
  module Tracing
    module Contrib
      module GRPC
        module Distributed
          # Extracts and injects propagation through gRPC metadata.
          # @see https://github.com/grpc/grpc-go/blob/v1.50.1/Documentation/grpc-metadata.md
          class Propagation < Tracing::Distributed::Propagation
            def initialize(
              propagation_style_inject:,
              propagation_style_extract:,
              propagation_extract_first:
            )
              super(
                propagation_styles: {
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_MULTI_HEADER =>
                    Tracing::Distributed::B3Multi.new(fetcher: Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER =>
                    Tracing::Distributed::B3Single.new(fetcher: Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_DATADOG =>
                    Tracing::Distributed::Datadog.new(fetcher: Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_TRACE_CONTEXT =>
                    Tracing::Distributed::TraceContext.new(fetcher: Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_BAGGAGE =>
                    Tracing::Distributed::Baggage.new(fetcher: Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_NONE => Tracing::Distributed::None.new
                },
                propagation_style_inject: propagation_style_inject,
                propagation_style_extract: propagation_style_extract,
                propagation_extract_first: propagation_extract_first
              )
            end
          end
        end
      end
    end
  end
end
