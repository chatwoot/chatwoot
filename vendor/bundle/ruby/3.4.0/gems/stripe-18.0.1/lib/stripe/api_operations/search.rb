# frozen_string_literal: true

module Stripe
  module APIOperations
    # The _search method via API Operations is deprecated.
    # Please use the search method from within the resource instead.
    module Search
      def _search(search_url, filters = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: search_url,
          params: filters,
          opts: opts
        )
      end

      extend Gem::Deprecate
      deprecate :_search, "request_stripe_object", 2024, 1
    end
  end
end
