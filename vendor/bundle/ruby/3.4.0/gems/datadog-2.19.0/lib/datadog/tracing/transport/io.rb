# frozen_string_literal: true

require_relative '../../core/encoding'
require_relative 'io/client'
require_relative 'io/traces'

module Datadog
  module Tracing
    module Transport
      # Namespace for IO transport components
      module IO
        module_function

        # Builds a new Transport::IO::Client
        def new(out, encoder)
          Client.new(out, encoder)
        end

        # Builds a new Transport::IO::Client with default settings
        # Pass options to override any settings.
        def default(options = {})
          new(
            options.fetch(:out, $stdout),
            options.fetch(:encoder, Core::Encoding::JSONEncoder)
          )
        end
      end
    end
  end
end
