# frozen_string_literal: true

module Datadog
  # Datadog::Kit holds public-facing APIs for higher level user-facing
  # features, these features not belonging to a specific product. Contrary to
  # Datadog::Core, Kit depends on products.
  module Kit
  end
end

require_relative 'kit/identity'
