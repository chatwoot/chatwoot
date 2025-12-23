# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Enforces consistent use of `be_a` or `be_kind_of`.
      #
      # @example EnforcedStyle: be_a (default)
      #   # bad
      #   expect(object).to be_kind_of(String)
      #   expect(object).to be_a_kind_of(String)
      #
      #   # good
      #   expect(object).to be_a(String)
      #   expect(object).to be_an(String)
      #
      # @example EnforcedStyle: be_kind_of
      #   # bad
      #   expect(object).to be_a(String)
      #   expect(object).to be_an(String)
      #
      #   # good
      #   expect(object).to be_kind_of(String)
      #   expect(object).to be_a_kind_of(String)
      #
      class ClassCheck < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG = 'Prefer `%<preferred>s` over `%<current>s`.'

        METHOD_NAMES_FOR_BE_A = ::Set[
          :be_a,
          :be_an
        ].freeze

        METHOD_NAMES_FOR_KIND_OF = ::Set[
          :be_a_kind_of,
          :be_kind_of
        ].freeze

        PREFERRED_METHOD_NAME_BY_STYLE = {
          be_a: :be_a,
          be_kind_of: :be_kind_of
        }.freeze

        RESTRICT_ON_SEND = %i[
          be_a
          be_a_kind_of
          be_an
          be_kind_of
        ].freeze

        def on_send(node)
          return unless offending?(node)

          add_offense(
            node.loc.selector,
            message: format_message(node)
          ) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          corrector.replace(node.loc.selector, preferred_method_name)
        end

        def format_message(node)
          format(
            MSG,
            current: node.method_name,
            preferred: preferred_method_name
          )
        end

        def offending?(node)
          !node.receiver && !preferred_method_name?(node.method_name)
        end

        def preferred_method_name?(method_name)
          preferred_method_names.include?(method_name)
        end

        def preferred_method_name
          PREFERRED_METHOD_NAME_BY_STYLE[style]
        end

        def preferred_method_names
          if style == :be_a
            METHOD_NAMES_FOR_BE_A
          else
            METHOD_NAMES_FOR_KIND_OF
          end
        end
      end
    end
  end
end
