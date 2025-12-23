# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for `expect(...)` calls containing literal values.
      #
      # Autocorrection is performed when the expected is not a literal.
      #
      # @example
      #   # bad
      #   expect(5).to eq(price)
      #   expect(/foo/).to eq(pattern)
      #   expect("John").to eq(name)
      #
      #   # good
      #   expect(price).to eq(5)
      #   expect(pattern).to eq(/foo/)
      #   expect(name).to eq("John")
      #
      #   # bad (not supported autocorrection)
      #   expect(false).to eq(true)
      #
      class ExpectActual < Base
        extend AutoCorrector

        MSG = 'Provide the actual value you are testing to `expect(...)`.'

        RESTRICT_ON_SEND = Runners.all

        SIMPLE_LITERALS = %i[
          true
          false
          nil
          int
          float
          str
          sym
          complex
          rational
          regopt
        ].freeze

        COMPLEX_LITERALS = %i[
          array
          hash
          pair
          irange
          erange
          regexp
        ].freeze

        SKIPPED_MATCHERS = %i[route_to be_routable].freeze
        CORRECTABLE_MATCHERS = %i[eq eql equal be].freeze

        # @!method expect_literal(node)
        def_node_matcher :expect_literal, <<~PATTERN
          (send
            (send nil? :expect $#literal?)
            #Runners.all
            ${
              (send (send nil? $:be) :== $_)
              (send nil? $_ $_ ...)
            }
          )
        PATTERN

        def on_send(node)
          expect_literal(node) do |actual, send_node, matcher, expected|
            next if SKIPPED_MATCHERS.include?(matcher)

            add_offense(actual) do |corrector|
              next unless CORRECTABLE_MATCHERS.include?(matcher)
              next if literal?(expected)

              corrector.replace(actual, expected.source)
              if matcher == :be
                corrector.replace(expected, actual.source)
              else
                corrector.replace(send_node, "#{matcher}(#{actual.source})")
              end
            end
          end
        end

        private

        # This is not implemented using a NodePattern because it seems
        # to not be able to match against an explicit (nil) sexp
        def literal?(node)
          node && (simple_literal?(node) || complex_literal?(node))
        end

        def simple_literal?(node)
          SIMPLE_LITERALS.include?(node.type)
        end

        def complex_literal?(node)
          COMPLEX_LITERALS.include?(node.type) &&
            node.each_child_node.all? { |child_node| literal?(child_node) }
        end
      end
    end
  end
end
