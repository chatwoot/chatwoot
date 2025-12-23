# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Detects cases where the `:foreign_key` option on associations
      # is redundant.
      #
      # @example
      #   # bad
      #   class Post
      #     has_many :comments, foreign_key: 'post_id'
      #   end
      #
      #   class Comment
      #     belongs_to :post, foreign_key: 'post_id'
      #   end
      #
      #   # good
      #   class Post
      #     has_many :comments
      #   end
      #
      #   class Comment
      #     belongs_to :author, foreign_key: 'user_id'
      #   end
      class RedundantForeignKey < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Specifying the default value for `foreign_key` is redundant.'
        RESTRICT_ON_SEND = %i[belongs_to has_one has_many has_and_belongs_to_many].freeze

        def_node_matcher :association_with_foreign_key, <<~PATTERN
          (send nil? ${:belongs_to :has_one :has_many :has_and_belongs_to_many} ({sym str} $_)
            $(hash <$(pair (sym :foreign_key) ({sym str} $_)) ...>)
          )
        PATTERN

        def on_send(node)
          association_with_foreign_key(node) do |type, name, options, foreign_key_pair, foreign_key|
            if redundant?(node, type, name, options, foreign_key)
              add_offense(foreign_key_pair) do |corrector|
                range = range_with_surrounding_space(foreign_key_pair.source_range, side: :left)
                range = range_with_surrounding_comma(range, :left)

                corrector.remove(range)
              end
            end
          end
        end

        private

        def redundant?(node, association_type, association_name, options, foreign_key)
          foreign_key.to_s == default_foreign_key(node, association_type, association_name, options)
        end

        def default_foreign_key(node, association_type, association_name, options)
          if association_type == :belongs_to
            "#{association_name}_id"
          elsif (as = find_as_option(options))
            "#{as}_id"
          else
            node.parent_module_name&.foreign_key
          end
        end

        def find_as_option(options)
          options.pairs.find do |pair|
            pair.key.sym_type? && pair.key.value == :as
          end&.value&.value
        end
      end
    end
  end
end
