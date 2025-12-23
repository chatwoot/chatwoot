# frozen_string_literal: true

module RuboCop
  module Cop
    # This module provides functionality for checking if numbering match the
    # configured EnforcedStyle.
    module ConfigurableNumbering
      include ConfigurableFormatting

      implicit_param = /\A_\d+\z/
      FORMATS = {
        snake_case:  /(?:\D|_\d+|\A\d+)\z/,
        normalcase:  /(?:\D|[^_\d]\d+|\A\d+)\z|#{implicit_param}/,
        non_integer: /(\D|\A\d+)\z|#{implicit_param}/
      }.freeze
    end
  end
end
