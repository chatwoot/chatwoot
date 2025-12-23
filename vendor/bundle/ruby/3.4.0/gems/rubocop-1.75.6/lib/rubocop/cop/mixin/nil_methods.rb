# frozen_string_literal: true

module RuboCop
  module Cop
    # This module provides a list of methods that are:
    # 1. In the NilClass by default
    # 2. Added to NilClass by explicitly requiring any standard libraries
    # 3. Cop's configuration parameter AllowedMethods.
    module NilMethods
      include AllowedMethods

      private

      def nil_methods
        nil.methods + other_stdlib_methods + allowed_methods.map(&:to_sym)
      end

      def other_stdlib_methods
        [:to_d]
      end
    end
  end
end
