# frozen_string_literal: true

require 'delegate'

module Lograge
  class SilentLogger < SimpleDelegator
    %i[debug info warn error fatal unknown].each do |method_name|
      # rubocop:disable Lint/EmptyBlock
      define_method(method_name) { |*_args| }
      # rubocop:enable Lint/EmptyBlock
    end
  end
end
