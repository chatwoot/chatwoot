# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces the use of `pick` over `pluck(...).first`.
      #
      # Using `pluck` followed by `first` creates an intermediate array, which
      # `pick` avoids. When called on an Active Record relation, `pick` adds a
      # limit to the query so that only one value is fetched from the database.
      #
      # Note that when `pick` is added to a relation with an existing limit, it
      # causes a subquery to be added. In most cases this is undesirable, and
      # care should be taken while resolving this violation.
      #
      # @safety
      #   This cop is unsafe because `pluck` is defined on both `ActiveRecord::Relation` and `Enumerable`,
      #   whereas `pick` is only defined on `ActiveRecord::Relation` in Rails 6.0. This was addressed
      #   in Rails 6.1 via rails/rails#38760, at which point the cop is safe.
      #
      #   See: https://github.com/rubocop/rubocop-rails/pull/249
      #
      # @example
      #   # bad
      #   Model.pluck(:a).first
      #   [{ a: :b, c: :d }].pluck(:a, :b).first
      #
      #   # good
      #   Model.pick(:a)
      #   [{ a: :b, c: :d }].pick(:a, :b)
      class Pick < Base
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Prefer `pick(%<args>s)` over `%<current>s`.'
        RESTRICT_ON_SEND = %i[first].freeze

        minimum_target_rails_version 6.0

        def_node_matcher :pick_candidate?, <<~PATTERN
          (call (call _ :pluck ...) :first)
        PATTERN

        def on_send(node)
          pick_candidate?(node) do
            receiver = node.receiver
            receiver_selector = receiver.loc.selector
            node_selector = node.loc.selector
            range = receiver_selector.join(node_selector)

            add_offense(range, message: message(receiver, range)) do |corrector|
              first_range = receiver.source_range.end.join(node_selector)

              corrector.remove(first_range)
              corrector.replace(receiver_selector, 'pick')
            end
          end
        end
        alias on_csend on_send

        private

        def message(receiver, current)
          format(MSG, args: receiver.arguments.map(&:source).join(', '), current: current.source)
        end
      end
    end
  end
end
