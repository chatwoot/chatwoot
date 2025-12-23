# frozen_string_literal: true

require_relative '../../../distributed/fetcher'
require_relative '../../../distributed/propagation'
require_relative '../../../distributed/b3_multi'
require_relative '../../../distributed/b3_single'
require_relative '../../../distributed/datadog'
require_relative '../../../distributed/none'
require_relative '../../../distributed/trace_context'
require_relative '../../../configuration/ext'

module Datadog
  module Tracing
    module Contrib
      module Karafka
        module Distributed
          # Extracts and injects propagation through Kafka message headers.
          class Propagation < Tracing::Distributed::Propagation
            def initialize(
              propagation_style_inject:,
              propagation_style_extract:,
              propagation_extract_first:
            )
              super(
                propagation_styles: {
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_MULTI_HEADER =>
                    Tracing::Distributed::B3Multi.new(fetcher: Tracing::Distributed::Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER =>
                    Tracing::Distributed::B3Single.new(fetcher: Tracing::Distributed::Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_DATADOG =>
                    Tracing::Distributed::Datadog.new(fetcher: Tracing::Distributed::Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_TRACE_CONTEXT =>
                    Tracing::Distributed::TraceContext.new(fetcher: Tracing::Distributed::Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_BAGGAGE =>
                    Tracing::Distributed::Baggage.new(fetcher: Tracing::Distributed::Fetcher),
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
