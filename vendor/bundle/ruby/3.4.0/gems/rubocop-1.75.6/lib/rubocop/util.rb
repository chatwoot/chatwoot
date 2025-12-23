# frozen_string_literal: true

module RuboCop
  # This module contains a collection of useful utility methods.
  module Util
    def self.silence_warnings
      # Replaces Kernel::silence_warnings since it hides any warnings,
      # including the RuboCop ones
      old_verbose = $VERBOSE
      $VERBOSE = nil
      yield
    ensure
      $VERBOSE = old_verbose
    end
  end
end
