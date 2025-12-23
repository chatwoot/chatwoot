# frozen_string_literal: true

module Aws
  module TokenProvider

    # @return [Token]
    attr_reader :token

    # @return [Boolean]
    def set?
      !!token && token.set?
    end

  end
end
