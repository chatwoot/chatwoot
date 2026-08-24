# frozen_string_literal: true

# [whisker] Whisker product namespace
# Provides product-level helpers without leaking upstream class names into app code.
module Whisker
  def self.version
    Chatwoot.config[:version].presence || '1.0.0'
  rescue StandardError
    '1.0.0'
  end
end
