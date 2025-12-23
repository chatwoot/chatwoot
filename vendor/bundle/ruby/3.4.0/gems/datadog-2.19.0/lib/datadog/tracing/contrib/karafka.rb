# frozen_string_literal: true

require_relative 'component'
require_relative 'karafka/integration'
require_relative 'karafka/distributed/propagation'

module Datadog
  module Tracing
    module Contrib
      # `Karafka` integration public API
      module Karafka
        def self.inject(digest, data)
          raise 'Please invoke Datadog.configure at least once before calling this method' unless @propagation

          @propagation.inject!(digest, data)
        end

        def self.extract(data)
          raise 'Please invoke Datadog.configure at least once before calling this method' unless @propagation

          @propagation.extract(data)
        end

        Contrib::Component.register('karafka') do |config|
          tracing = config.tracing
          tracing.propagation_style

          @propagation = Karafka::Distributed::Propagation.new(
            propagation_style_inject: tracing.propagation_style_inject,
            propagation_style_extract: tracing.propagation_style_extract,
            propagation_extract_first: tracing.propagation_extract_first
          )
        end
      end
    end
  end
end
