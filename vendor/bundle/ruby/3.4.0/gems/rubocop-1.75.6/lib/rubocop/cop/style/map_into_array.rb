# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for usages of `each` with `<<`, `push`, or `append` which
      # can be replaced by `map`.
      #
      # If `PreferredMethods` is configured for `map` in `Style/CollectionMethods`,
      # this cop uses the specified method for replacement.
      #
      # NOTE: The return value of `Enumerable#each` is `self`, whereas the
      # return value of `Enumerable#map` is an `Array`. They are not autocorrected
      # when a return value could be used because these types differ.
      #
      # NOTE: It only detects when the mapping destination is either:
      # * a local variable initialized as an empty array and referred to only by the
      # pushing operation;
      # * or, if it is the single block argument to a `[].tap` block.
      # This is because, if not, it's challenging to statically guarantee that the
      # mapping destination variable remains an empty array:
      #
      # [source,ruby]
      # ----
      # ret = []
      # src.each { |e| ret << e * 2 } # `<<` method may mutate `ret`
      #
      # dest = []
      # src.each { |e| dest << transform(e, dest) } # `transform` method may mutate `dest`
      # ----
      #
      # @safety
      #   This cop is unsafe because not all objects that have an `each`
      #   method also have a `map` method (e.g. `ENV`). Additionally, for calls
      #   with a block, not all objects that have a `map` method return an array
      #   (e.g. `Enumerator::Lazy`).
      #
      # @example
      #   # bad
      #   dest = []
      #   src.each { |e| dest << e * 2 }
      #   dest
      #
      #   # good
      #   dest = src.map { |e| e * 2 }
      #
      #   # bad
      #   [].tap do |dest|
      #     src.each { |e| dest << e * 2 }
      #   end
      #
      #   # good
      #   dest = src.map { |e| e * 2 }
      #
      #   # good - contains another operation
      #   dest = []
      #   src.each { |e| dest << e * 2; puts e }
      #   dest
      #
      class MapIntoArray < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<new_method_name>s` instead of `each` to map elements into an array.'

        # @!method suitable_argument_node?(node)
        def_node_matcher :suitable_argument_node?, <<-PATTERN
          !{splat forwarded-restarg forwarded-args (hash (forwarded-kwrestarg)) (block-pass nil?)}
        PATTERN

        # @!method each_block_with_push?(node)
        def_node_matcher :each_block_with_push?, <<-PATTERN
          [
            ^({begin kwbegin block} ...)
            (any_block (send !{nil? self} :each) _
              (send (lvar _) {:<< :push :append} #suitable_argument_node?))
          ]
        PATTERN

        # @!method empty_array_asgn?(node)
        def_node_matcher :empty_array_asgn?, <<~PATTERN
          (
            lvasgn _ {
              (array)
              (send (const {nil? cbase} :Array) :[])
              (send (const {nil? cbase} :Array) :new (array)?)
              (send nil? :Array (array))
            }
          )
        PATTERN

        # @!method empty_array_tap(node)
        def_node_matcher :empty_array_tap, <<~PATTERN
          ^^$(
            block
              (send (array) :tap)
              (args (arg _))
              ...
          )
        PATTERN

        # @!method lvar_ref?(node, name)
        def_node_matcher :lvar_ref?, '(lvar %1)'

        def self.joining_forces
          VariableForce
        end

        def after_leaving_scope(scope, _variable_table)
          (@scopes ||= []) << scope
        end

        def on_block(node)
          return unless each_block_with_push?(node)

          dest_var = find_dest_var(node)

          if offending_empty_array_tap?(node, dest_var)
            asgn = dest_var.declaration_node
          else
            return unless (asgn = find_closest_assignment(node, dest_var))
            return unless empty_array_asgn?(asgn)
            return unless dest_used_only_for_mapping?(node, dest_var, asgn)
          end

          register_offense(node, dest_var, asgn)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def find_dest_var(block)
          node = block.body.receiver
          name = node.children.first

          candidates = @scopes.lazy.filter_map { |s| s.variables[name] }
          candidates.find { |v| v.references.any? { |n| n.node.equal?(node) } }
        end

        def offending_empty_array_tap?(node, dest_var)
          return false unless (tap_block_node = empty_array_tap(dest_var.declaration_node))

          # A `tap` block only offends if the array push is the only thing in it;
          # otherwise we cannot guarantee that the block variable is still an empty
          # array when pushed to.
          tap_block_node.body == node
        end

        def find_closest_assignment(block, dest_var)
          dest_var.assignments.reverse_each.lazy.map(&:node).find do |node|
            node.source_range.end_pos < block.source_range.begin_pos
          end
        end

        def dest_used_only_for_mapping?(block, dest_var, asgn)
          range = asgn.source_range.join(block.source_range)

          asgn.parent.equal?(block.parent) &&
            dest_var.references.one? { |r| range.contains?(r.node.source_range) } &&
            dest_var.assignments.one? { |a| range.contains?(a.node.source_range) }
        end

        def register_offense(block, dest_var, asgn)
          add_offense(block, message: format(MSG, new_method_name: new_method_name)) do |corrector|
            next if return_value_used?(block)

            corrector.replace(block.send_node.selector, new_method_name)

            if (tap_block_node = empty_array_tap(dest_var.declaration_node))
              remove_tap(corrector, block, tap_block_node)
            else
              remove_assignment(corrector, asgn)
            end

            correct_push_node(corrector, block.body)
            correct_return_value_handling(corrector, block, dest_var)
          end
        end

        def new_method_name
          default = 'map'
          alternative = config.for_cop('Style/CollectionMethods').dig('PreferredMethods', default)
          alternative || default
        end

        def return_value_used?(node)
          parent = node.parent

          case parent&.type
          when nil
            false
          when :begin, :kwbegin
            !node.right_sibling && return_value_used?(parent)
          else
            !parent.respond_to?(:void_context?) || !parent.void_context?
          end
        end

        def remove_assignment(corrector, asgn)
          range = range_with_surrounding_space(asgn.source_range, side: :right)
          range = range_with_surrounding_space(range, side: :right, newlines: false)

          corrector.remove(range)
        end

        def remove_tap(corrector, node, block_node)
          range = range_between(block_node.source_range.begin_pos, node.source_range.begin_pos)
          corrector.remove(range)
          corrector.remove(range_with_surrounding_space(block_node.loc.end, side: :left))
        end

        def correct_push_node(corrector, push_node)
          arg_node = push_node.first_argument
          range = push_node.source_range
          arg_range = arg_node.source_range

          corrector.wrap(arg_node, '{ ', ' }') if arg_node.hash_type? && !arg_node.braces?
          corrector.remove(range_between(range.begin_pos, arg_range.begin_pos))
          corrector.remove(range_between(arg_range.end_pos, range.end_pos))
        end

        def correct_return_value_handling(corrector, block, dest_var)
          next_node = block.right_sibling

          if lvar_ref?(next_node, dest_var.name)
            corrector.remove(range_with_surrounding_space(next_node.source_range, side: :left))
          end

          corrector.insert_before(block, "#{dest_var.name} = ")
        end
      end
    end
  end
end
