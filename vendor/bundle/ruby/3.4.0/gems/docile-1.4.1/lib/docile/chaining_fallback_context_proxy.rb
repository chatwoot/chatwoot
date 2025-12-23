# frozen_string_literal: true

require "docile/fallback_context_proxy"

module Docile
  # @api private
  #
  # Operates in the same manner as {FallbackContextProxy}, but replacing
  # the primary `receiver` object with the result of each proxied method.
  #
  # This is useful for implementing DSL evaluation for immutable context
  # objects.
  #
  # @see Docile.dsl_eval_immutable
  #
  # rubocop:disable Style/MissingRespondToMissing
  class ChainingFallbackContextProxy < FallbackContextProxy
    # Proxy methods as in {FallbackContextProxy#method_missing}, replacing
    # `receiver` with the returned value.
    def method_missing(method, *args, &block)
      @__receiver__ = super
    end

    ruby2_keywords :method_missing if respond_to?(:ruby2_keywords, true)
  end
  # rubocop:enable Style/MissingRespondToMissing
end
