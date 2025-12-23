# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces the use of `pluck` over `map`.
      #
      # `pluck` can be used instead of `map` to extract a single key from each
      # element in an enumerable. When called on an Active Record relation, it
      # results in a more efficient query that only selects the necessary key.
      #
      # NOTE: If the receiver's relation is not loaded and `pluck` is used inside an iteration,
      # it may result in N+1 queries because `pluck` queries the database on each iteration.
      # This cop ignores offenses for `map/collect` when they are suspected to be part of an iteration
      # to prevent such potential issues.
      #
      # [source,ruby]
      # ----
      # users = User.all
      # 5.times do
      #   users.map { |user| user[:foo] } # Only one query is executed
      # end
      #
      # users = User.all
      # 5.times do
      #   users.pluck(:id) # A query is executed on every iteration
      # end
      # ----
      #
      # @safety
      #   This cop is unsafe because model can use column aliases.
      #
      #   [source,ruby]
      #   ----
      #   # Original code
      #   User.select('name AS nickname').map { |user| user[:nickname] } # => array of nicknames
      #
      #   # After autocorrection
      #   User.select('name AS nickname').pluck(:nickname) # => raises ActiveRecord::StatementInvalid
      #   ----
      #
      # @example
      #   # bad
      #   Post.published.map { |post| post[:title] }
      #   [{ a: :b, c: :d }].collect { |el| el[:a] }
      #
      #   # good
      #   Post.published.pluck(:title)
      #   [{ a: :b, c: :d }].pluck(:a)
      class Pluck < Base
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Prefer `%<replacement>s` over `%<current>s`.'

        minimum_target_rails_version 5.0

        def_node_matcher :pluck_candidate?, <<~PATTERN
          (any_block (call _ {:map :collect}) $_argument (send lvar :[] $_key))
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_block(node)
          return if node.each_ancestor(:any_block).any?

          pluck_candidate?(node) do |argument, key|
            next if key.regexp_type? || !use_one_block_argument?(argument)

            match = if node.block_type?
                      block_argument = argument.children.first.source
                      use_block_argument_in_key?(block_argument, key)
                    elsif node.numblock_type?
                      use_block_argument_in_key?('_1', key)
                    else # itblock
                      use_block_argument_in_key?('it', key)
                    end
            next unless match

            register_offense(node, key)
          end
        end
        # rubocop:enable Metrics/AbcSize
        alias on_numblock on_block
        alias on_itblock on_block

        private

        def use_one_block_argument?(argument)
          # Checks for numbered argument `_1` or `it block parameter.
          return true if [1, :it].include?(argument)

          argument.respond_to?(:one?) && argument.one?
        end

        def use_block_argument_in_key?(block_argument, key)
          return false if block_argument == key.source

          key.each_descendant(:lvar).none? { |lvar| block_argument == lvar.source }
        end

        def offense_range(node)
          node.send_node.loc.selector.join(node.loc.end)
        end

        def register_offense(node, key)
          replacement = "pluck(#{key.source})"
          message = message(replacement, node)

          add_offense(offense_range(node), message: message) do |corrector|
            corrector.replace(offense_range(node), replacement)
          end
        end

        def message(replacement, node)
          current = offense_range(node).source

          format(MSG, replacement: replacement, current: current)
        end
      end
    end
  end
end
