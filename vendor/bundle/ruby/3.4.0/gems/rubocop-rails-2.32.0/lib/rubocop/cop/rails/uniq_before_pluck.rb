# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Prefer using `distinct` before `pluck` instead of `uniq` after `pluck`.
      #
      # The use of distinct before pluck is preferred because it executes by
      # the database.
      #
      # This cop has two different enforcement modes. When the EnforcedStyle
      # is `conservative` (the default), then only calls to `pluck` on a constant
      # (i.e. a model class) before `uniq` are added as offenses.
      #
      # When the EnforcedStyle is `aggressive` then all calls to `pluck` before
      # distinct are added as offenses. This may lead to false positives
      # as the cop cannot distinguish between calls to `pluck` on an
      # ActiveRecord::Relation vs a call to pluck on an
      # ActiveRecord::Associations::CollectionProxy.
      #
      # @safety
      #   This cop is unsafe for autocorrection because the behavior may change
      #   depending on the database collation.
      #
      # @example EnforcedStyle: conservative (default)
      #   # bad - redundantly fetches duplicate values
      #   Album.pluck(:band_name).uniq
      #
      #   # good
      #   Album.distinct.pluck(:band_name)
      #
      # @example EnforcedStyle: aggressive
      #   # bad - redundantly fetches duplicate values
      #   Album.pluck(:band_name).uniq
      #
      #   # bad - redundantly fetches duplicate values
      #   Album.where(year: 1985).pluck(:band_name).uniq
      #
      #   # bad - redundantly fetches duplicate values
      #   customer.favourites.pluck(:color).uniq
      #
      #   # good
      #   Album.distinct.pluck(:band_name)
      #   Album.distinct.where(year: 1985).pluck(:band_name)
      #   customer.favourites.distinct.pluck(:color)
      #
      class UniqBeforePluck < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `distinct` before `pluck`.'
        RESTRICT_ON_SEND = %i[uniq].freeze

        def_node_matcher :uniq_before_pluck, '[!^any_block $(send $(send _ :pluck ...) :uniq ...)]'

        def on_send(node)
          uniq_before_pluck(node) do |uniq_node, pluck_node|
            next if style == :conservative && !pluck_node.receiver&.const_type?

            add_offense(uniq_node.loc.selector) do |corrector|
              autocorrect(corrector, uniq_node, pluck_node)
            end
          end
        end

        private

        def autocorrect(corrector, uniq_node, pluck_node)
          corrector.remove(range_between(pluck_node.loc.end.end_pos, uniq_node.loc.selector.end_pos))

          if (dot = pluck_node.loc.dot)
            corrector.insert_before(dot.begin, '.distinct')
          else
            corrector.insert_before(pluck_node, 'distinct.')
          end
        end
      end
    end
  end
end
