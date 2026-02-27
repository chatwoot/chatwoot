# frozen_string_literal: true

module Aloo
  # CRITICAL: Do not change dimension without migration!
  # text-embedding-3-large with dimensions truncated to 1536 (MRL)
  EMBEDDING_DIMENSION = 1536

  SUPPORTED_SOURCE_TYPES = %w[file website text article].freeze
end
