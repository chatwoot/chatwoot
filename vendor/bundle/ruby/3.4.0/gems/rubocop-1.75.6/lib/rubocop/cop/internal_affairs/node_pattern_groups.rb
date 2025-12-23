# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Use node groups (`any_block`, `argument`, `boolean`, `call`, `numeric`, `range`)
      # in node patterns instead of a union (`{ ... }`) of the member types of the group.
      #
      # @example
      #   # bad
      #   def_node_matcher :my_matcher, <<~PATTERN
      #     {send csend}
      #   PATTERN
      #
      #   # good
      #   def_node_matcher :my_matcher, <<~PATTERN
      #     call
      #   PATTERN
      #
      class NodePatternGroups < Base
        require_relative 'node_pattern_groups/ast_processor'
        require_relative 'node_pattern_groups/ast_walker'

        include RangeHelp
        extend AutoCorrector

        MSG = 'Replace `%<names>s` in node pattern union with `%<replacement>s`.'
        RESTRICT_ON_SEND = %i[def_node_matcher def_node_search].freeze
        NODE_GROUPS = {
          any_block: %i[block numblock itblock],
          any_def: %i[def defs],
          argument: %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg forward_arg shadowarg],
          boolean: %i[true false],
          call: %i[send csend],
          numeric: %i[int float rational complex],
          range: %i[irange erange]
        }.freeze

        def on_new_investigation
          @walker = ASTWalker.new
        end

        # When a Node Pattern matcher is defined, investigate the pattern string to search
        # for node types that can be replaced with a node group (ie. `{send csend}` can be
        # replaced with `call`).
        #
        # In order to deal with node patterns in an efficient and non-brittle way, we will
        # parse the Node Pattern string given to this `send` node using
        # `RuboCop::AST::NodePattern::Parser::WithMeta`. `WithMeta` is important! We need
        # location information so that we can calculate the exact locations within the
        # pattern to report and correct.
        #
        # The resulting AST is processed by `NodePatternGroups::ASTProccessor` which rewrites
        # the AST slightly to handle node sequences (ie. `(send _ :foo ...)`). See the
        # documentation of that class for more details.
        #
        # Then the processed AST is walked, and metadata is collected for node types that
        # can be replaced with a node group.
        #
        # Finally, the metadata is used to register offenses and make corrections, using
        # the location data captured earlier. The ranges captured while parsing the Node
        # Pattern are offset using the string argument to this `send` node to ensure
        # that offenses are registered at the correct location.
        #
        def on_send(node)
          pattern_node = node.arguments[1]
          return unless acceptable_heredoc?(pattern_node) || pattern_node.str_type?

          process_pattern(pattern_node)
          return if node_groups.nil?

          apply_range_offsets(pattern_node)

          node_groups.each_with_index do |group, index|
            register_offense(group, index)
          end
        end

        def after_send(_)
          @walker.reset!
        end

        private

        def node_groups
          @walker.node_groups
        end

        # rubocop:disable InternalAffairs/RedundantSourceRange -- `node` here is a NodePatternNode
        def register_offense(group, index)
          replacement = replacement(group)
          message = format(
            MSG,
            names: group.node_types.map { |node| node.source_range.source }.join('`, `'),
            replacement: replacement
          )

          add_offense(group.offense_range, message: message) do |corrector|
            # Only correct one group at a time to avoid clobbering.
            # Other offenses will be corrected in the subsequent iterations of the
            # correction loop.
            next if index.positive?

            if group.other_elements?
              replace_types_with_node_group(corrector, group, replacement)
            else
              replace_union(corrector, group, replacement)
            end
          end
        end

        def replacement(group)
          if group.sequence?
            # If the original nodes were in a sequence (ie. wrapped in parentheses),
            # use it to generate the resulting NodePattern syntax.
            first_node_type = group.node_types.first
            template = first_node_type.source_range.source
            template.sub(first_node_type.child.to_s, group.name.to_s)
          else
            group.name
          end
        end
        # rubocop:enable InternalAffairs/RedundantSourceRange

        # When there are other elements in the union, remove the node types that can be replaced.
        def replace_types_with_node_group(corrector, group, replacement)
          ranges = group.ranges.map.with_index do |range, index|
            # Collect whitespace and pipes preceding each element
            range_for_full_union_element(range, index, group.pipe)
          end

          ranges.each { |range| corrector.remove(range) }

          corrector.insert_before(ranges.first, replacement)
        end

        # If the union contains pipes, remove the pipe character as well.
        # Unfortunately we don't get the location of the pipe in `loc` object, so we have
        # to find it.
        def range_for_full_union_element(range, index, pipe)
          if index.positive?
            range = if pipe
                      range_with_preceding_pipe(range)
                    else
                      range_with_surrounding_space(range: range, side: :left, newlines: true)
                    end
          end

          range
        end

        # Collect a preceding pipe and any whitespace left of the pipe
        def range_with_preceding_pipe(range)
          pos = range.begin_pos - 1

          while pos
            unless processed_source.buffer.source[pos].match?(/[\s|]/)
              return range.with(begin_pos: pos + 1)
            end

            pos -= 1
          end

          range
        end

        # When there are no other elements, the entire union can be replaced
        def replace_union(corrector, group, replacement)
          corrector.replace(group.ranges.first, replacement)
        end

        # rubocop:disable Metrics/AbcSize
        # Calculate the ranges for each node within the pattern string that will
        # be replaced or removed. Takes the offset of the string node into account.
        def apply_range_offsets(pattern_node)
          range, offset = range_with_offset(pattern_node)

          node_groups.each do |node_group|
            node_group.ranges ||= []
            node_group.offense_range = pattern_range(range, node_group.union, offset)

            if node_group.other_elements?
              node_group.node_types.each do |node_type|
                node_group.ranges << pattern_range(range, node_type, offset)
              end
            else
              node_group.ranges << node_group.offense_range
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        def pattern_range(range, node, offset)
          begin_pos = node.source_range.begin_pos
          end_pos = node.source_range.end_pos
          size = end_pos - begin_pos

          range.adjust(begin_pos: begin_pos + offset).resize(size)
        end

        def range_with_offset(pattern_node)
          if pattern_node.heredoc?
            [pattern_node.loc.heredoc_body, 0]
          else
            [pattern_node.source_range, pattern_node.loc.begin.size]
          end
        end

        # A heredoc can be a `dstr` without interpolation, but if there is interpolation
        # there'll be a `begin` node, in which case, we cannot evaluate the pattern.
        def acceptable_heredoc?(node)
          node.type?(:str, :dstr) && node.heredoc? && node.each_child_node(:begin).none?
        end

        def process_pattern(pattern_node)
          parser = RuboCop::AST::NodePattern::Parser::WithMeta.new
          ast = parser.parse(pattern_value(pattern_node))
          ast = ASTProcessor.new.process(ast)
          @walker.walk(ast)
        rescue RuboCop::AST::NodePattern::Invalid
          # if the pattern is invalid, no offenses will be registered
        end

        def pattern_value(pattern_node)
          pattern_node.heredoc? ? pattern_node.loc.heredoc_body.source : pattern_node.value
        end
      end
    end
  end
end
