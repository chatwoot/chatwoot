# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBot
      # Checks for redundant `factory` option.
      #
      # @example
      #   # bad
      #   association :user, factory: :user
      #
      #   # good
      #   association :user
      class RedundantFactoryOption < ::RuboCop::Cop::Base
        extend AutoCorrector

        include RangeHelp

        MSG = 'Remove redundant `factory` option.'

        RESTRICT_ON_SEND = %i[association].freeze

        # @!method association_with_a_factory_option(node)
        def_node_matcher :association_with_a_factory_option, <<~PATTERN
          (send nil? :association
            (sym $_association_name)
            ...
            (hash
              <$(pair
                  (sym :factory)
                  {
                    (sym $_factory_name)
                    (array (sym $_factory_name))
                  }
                )
                ...
              >
            )
          )
        PATTERN

        def on_send(node)
          association_with_a_factory_option(node) do
            |association_name, factory_option, factory_name|
            next if association_name != factory_name

            add_offense(factory_option) do |corrector|
              autocorrect(corrector, factory_option)
            end
          end
        end

        private

        def autocorrect(corrector, node)
          corrector.remove(
            range_with_surrounding_comma(
              range_with_surrounding_space(
                node.source_range,
                side: :left
              ),
              :left
            )
          )
        end
      end
    end
  end
end
