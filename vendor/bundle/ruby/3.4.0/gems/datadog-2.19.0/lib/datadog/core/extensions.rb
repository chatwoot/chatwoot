# frozen_string_literal: true

require_relative 'configuration'

# Global namespace that includes all Datadog functionality.
# @public_api
module Datadog
  module Core
    # Used to decorate Datadog module with additional behavior
    module Extensions
      def self.extended(base)
        base.extend(Core::Configuration)
      end
    end
  end
end
