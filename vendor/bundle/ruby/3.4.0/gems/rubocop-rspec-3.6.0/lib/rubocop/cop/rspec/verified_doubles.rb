# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Prefer using verifying doubles over normal doubles.
      #
      # @see https://rspec.info/features/3-12/rspec-mocks/verifying-doubles
      #
      # @example
      #   # bad
      #   let(:foo) do
      #     double(method_name: 'returned value')
      #   end
      #
      #   # bad
      #   let(:foo) do
      #     double("ClassName", method_name: 'returned value')
      #   end
      #
      #   # good
      #   let(:foo) do
      #     instance_double("ClassName", method_name: 'returned value')
      #   end
      #
      class VerifiedDoubles < Base
        MSG = 'Prefer using verifying doubles over normal doubles.'
        RESTRICT_ON_SEND = %i[double spy].freeze

        # @!method unverified_double(node)
        def_node_matcher :unverified_double, <<~PATTERN
          {(send nil? {:double :spy} $...)}
        PATTERN

        def on_send(node)
          unverified_double(node) do |name, *_args|
            return if name.nil? && cop_config['IgnoreNameless']
            return if symbol?(name) && cop_config['IgnoreSymbolicNames']

            add_offense(node)
          end
        end

        private

        def symbol?(name)
          name&.sym_type?
        end
      end
    end
  end
end
