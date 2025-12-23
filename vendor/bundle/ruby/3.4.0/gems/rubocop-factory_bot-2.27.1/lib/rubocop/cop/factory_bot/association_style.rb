# frozen_string_literal: true

module RuboCop
  module Cop
    module FactoryBot
      # Use a consistent style to define associations.
      #
      # @safety
      #   This cop may cause false-positives in `EnforcedStyle: explicit`
      #   case. It recognizes any method call that has no arguments as an
      #   implicit association but it might be a user-defined trait call.
      #
      # @example EnforcedStyle: implicit (default)
      #   # bad
      #   factory :post do
      #     association :user
      #   end
      #
      #   # good
      #   factory :post do
      #     user
      #   end
      #
      #   # bad
      #   factory :post do
      #     association :user, :author
      #   end
      #
      #   # good
      #   factory :post do
      #     user factory: %i[user author]
      #   end
      #
      # @example EnforcedStyle: explicit
      #   # bad
      #   factory :post do
      #     user
      #   end
      #
      #   # good
      #   factory :post do
      #     association :user
      #   end
      #
      #   # bad
      #   factory :post do
      #     user factory: %i[user author]
      #   end
      #
      #   # good
      #   factory :post do
      #     association :user, :author
      #   end
      #
      #   # good (NonImplicitAssociationMethodNames: ['email'])
      #   sequence :email do |n|
      #     "person#{n}@example.com"
      #   end
      #
      #   factory :user do
      #     email
      #   end
      class AssociationStyle < ::RuboCop::Cop::Base # rubocop:disable Metrics/ClassLength
        extend AutoCorrector

        include ConfigurableEnforcedStyle

        DEFAULT_NON_IMPLICIT_ASSOCIATION_METHOD_NAMES = %w[
          association
          factory
          sequence
          skip_create
          traits_for_enum
        ].freeze

        RESTRICT_ON_SEND = %i[factory trait].freeze
        KEYWORDS = %i[alias and begin break case class def defined? do
                      else elsif end ensure false for if in module
                      next nil not or redo rescue retry return self
                      super then true undef unless until when while
                      yield __FILE__ __LINE__ __ENCODING__].freeze

        def on_send(node)
          bad_associations_in(node).each do |association|
            add_offense(
              association,
              message: "Use #{style} style to define associations."
            ) do |corrector|
              autocorrect(corrector, association)
            end
          end
        end

        private

        # @!method explicit_association?(node)
        def_node_matcher :explicit_association?, <<~PATTERN
          (send nil? :association sym ...)
        PATTERN

        # @!method with_strategy_build_option?(node)
        def_node_matcher :with_strategy_build_option?, <<~PATTERN
          (send nil? :association sym ...
            (hash <(pair (sym :strategy) (sym :build)) ...>)
          )
        PATTERN

        # @!method implicit_association?(node)
        def_node_matcher :implicit_association?, <<~PATTERN
          (send nil? !#non_implicit_association_method_name? ...)
        PATTERN

        # @!method factory_option_matcher(node)
        def_node_matcher :factory_option_matcher, <<~PATTERN
          (send
            nil?
            :association
            ...
            (hash
              <
                (pair
                  (sym :factory)
                  {
                    (sym $_) |
                    (array (sym $_)*)
                  }
                )
                ...
              >
            )
          )
        PATTERN

        # @!method trait_names_from_explicit(node)
        def_node_matcher :trait_names_from_explicit, <<~PATTERN
          (send nil? :association _ (sym $_)* ...)
        PATTERN

        # @!method association_names(node)
        def_node_search :association_names, <<~PATTERN
          (send nil? :association $...)
        PATTERN

        # @!method trait_name(node)
        def_node_search :trait_name, <<~PATTERN
          (send nil? :trait (sym $_) )
        PATTERN

        def autocorrect(corrector, node)
          if style == :explicit
            autocorrect_to_explicit_style(corrector, node)
          else
            autocorrect_to_implicit_style(corrector, node)
          end
        end

        def autocorrect_to_explicit_style(corrector, node)
          arguments = [
            ":#{node.method_name}",
            *node.arguments.map(&:source)
          ]
          corrector.replace(node, "association #{arguments.join(', ')}")
        end

        def autocorrect_to_implicit_style(corrector, node)
          source = node.first_argument.value.to_s
          options = options_for_autocorrect_to_implicit_style(node)
          unless options.empty?
            rest = options.map { |option| option.join(': ') }.join(', ')
            source += " #{rest}"
          end
          corrector.replace(node, source)
        end

        def bad?(node)
          if style == :explicit
            implicit_association?(node) &&
              !trait_within_trait?(node)
          else
            explicit_association?(node) &&
              !with_strategy_build_option?(node) &&
              !keyword?(node)
          end
        end

        def keyword?(node)
          association_names(node).any? do |associations|
            associations.any? do |association|
              next unless association.sym_type?

              KEYWORDS.include?(association.value)
            end
          end
        end

        def bad_associations_in(node)
          children_of_factory_block(node).select do |child|
            bad?(child)
          end
        end

        def children_of_factory_block(node)
          block = node.block_node
          return [] unless block
          return [] unless block.body

          if block.body.begin_type?
            block.body.children
          else
            [block.body]
          end
        end

        def factory_names_from_explicit(node)
          trait_names = trait_names_from_explicit(node)
          factory_names = Array(factory_option_matcher(node))
          result = factory_names + trait_names
          if factory_names.empty? && !trait_names.empty?
            result.prepend(node.first_argument.value)
          end
          result
        end

        def non_implicit_association_method_name?(method_name)
          non_implicit_association_method_names.include?(method_name.to_s)
        end

        def non_implicit_association_method_names
          DEFAULT_NON_IMPLICIT_ASSOCIATION_METHOD_NAMES +
            (cop_config['NonImplicitAssociationMethodNames'] || [])
        end

        def options_from_explicit(node)
          return {} unless node.last_argument.hash_type?

          node.last_argument.pairs.inject({}) do |options, pair|
            options.merge(pair.key.value => pair.value.source)
          end
        end

        def options_for_autocorrect_to_implicit_style(node)
          options = options_from_explicit(node)
          factory_names = factory_names_from_explicit(node)
          unless factory_names.empty?
            options[:factory] = "%i[#{factory_names.join(' ')}]"
          end
          options
        end

        def trait_within_trait?(node)
          factory_node = node.ancestors.reverse.find do |ancestor|
            ancestor.method?(:factory) if ancestor.block_type?
          end

          trait_name(factory_node).include?(node.method_name)
        end
      end
    end
  end
end
