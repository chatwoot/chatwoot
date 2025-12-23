# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether the rescue and ensure keywords are aligned
      # properly.
      #
      # @example
      #
      #   # bad
      #   begin
      #     something
      #     rescue
      #     puts 'error'
      #   end
      #
      #   # good
      #   begin
      #     something
      #   rescue
      #     puts 'error'
      #   end
      class RescueEnsureAlignment < Base
        include RangeHelp
        include EndKeywordAlignment
        extend AutoCorrector

        MSG = '`%<kw_loc>s` at %<kw_loc_line>d, %<kw_loc_column>d is not ' \
              'aligned with `%<beginning>s` at ' \
              '%<begin_loc_line>d, %<begin_loc_column>d.'
        ANCESTOR_TYPES = %i[kwbegin any_def class module any_block].freeze
        ALTERNATIVE_ACCESS_MODIFIERS = %i[public_class_method private_class_method].freeze

        def on_resbody(node)
          check(node) unless modifier?(node)
        end

        def on_ensure(node)
          check(node)
        end

        def on_new_investigation
          @modifier_locations =
            processed_source.tokens.each_with_object([]) do |token, locations|
              next unless token.rescue_modifier?

              locations << token.pos
            end
        end

        private

        # Check alignment of node with rescue or ensure modifiers.

        def check(node)
          alignment_node = alignment_node(node)
          return if alignment_node.nil?

          alignment_loc = alignment_location(alignment_node)
          kw_loc        = node.loc.keyword

          return if alignment_loc.column == kw_loc.column || same_line?(alignment_loc, kw_loc)

          add_offense(
            kw_loc, message: format_message(alignment_node, alignment_loc, kw_loc)
          ) do |corrector|
            autocorrect(corrector, node, alignment_loc)
          end
        end

        def autocorrect(corrector, node, alignment_location)
          whitespace = whitespace_range(node)
          # Some inline node is sitting before current node.
          return nil unless whitespace.source.strip.empty?

          new_column = alignment_location.column

          corrector.replace(whitespace, ' ' * new_column)
        end

        def format_message(alignment_node, alignment_loc, kw_loc)
          format(
            MSG,
            kw_loc: kw_loc.source,
            kw_loc_line: kw_loc.line,
            kw_loc_column: kw_loc.column,
            beginning: alignment_source(alignment_node, alignment_loc),
            begin_loc_line: alignment_loc.line,
            begin_loc_column: alignment_loc.column
          )
        end

        # rubocop:disable Metrics/AbcSize
        def alignment_source(node, starting_loc)
          ending_loc =
            case node.type
            when :block, :numblock, :itblock, :kwbegin
              node.loc.begin
            when :def, :defs, :class, :module,
                 :lvasgn, :ivasgn, :cvasgn, :gvasgn, :casgn
              node.loc.name
            when :masgn
              node.lhs.source_range
            else
              # It is a wrapper with receiver of object attribute or access modifier.
              node.receiver&.source_range || node.child_nodes.first.loc.name
            end

          range_between(starting_loc.begin_pos, ending_loc.end_pos).source
        end
        # rubocop:enable Metrics/AbcSize

        # We will use ancestor or wrapper with access modifier.

        def alignment_node(node)
          ancestor_node = ancestor_node(node)

          return ancestor_node if ancestor_node.nil? || ancestor_node.kwbegin_type?
          return if ancestor_node.respond_to?(:send_node) &&
                    aligned_with_line_break_method?(ancestor_node, node)

          assignment_node = assignment_node(ancestor_node)
          return assignment_node if same_line?(ancestor_node, assignment_node)

          access_modifier_node = access_modifier_node(ancestor_node)
          return access_modifier_node unless access_modifier_node.nil?

          ancestor_node
        end

        def ancestor_node(node)
          node.each_ancestor(*ANCESTOR_TYPES).first
        end

        def aligned_with_line_break_method?(ancestor_node, node)
          send_node_loc = ancestor_node.send_node.loc
          do_keyword_line = ancestor_node.loc.begin.line
          rescue_keyword_column = node.loc.keyword.column
          selector = send_node_loc.respond_to?(:selector) ? send_node_loc.selector : send_node_loc

          if aligned_with_leading_dot?(do_keyword_line, send_node_loc, rescue_keyword_column)
            return true
          end

          do_keyword_line == selector&.line && rescue_keyword_column == selector.column
        end

        def aligned_with_leading_dot?(do_keyword_line, send_node_loc, rescue_keyword_column)
          return false unless send_node_loc.respond_to?(:dot) && (dot = send_node_loc.dot)

          do_keyword_line == dot.line && rescue_keyword_column == dot.column
        end

        def assignment_node(node)
          assignment_node = node.ancestors.first
          return nil unless
            assignment_node&.assignment?

          assignment_node
        end

        def access_modifier_node(node)
          return nil unless node.any_def_type?

          access_modifier_node = node.ancestors.first
          return nil unless access_modifier?(access_modifier_node)

          access_modifier_node
        end

        def modifier?(node)
          return false unless @modifier_locations.respond_to?(:include?)

          @modifier_locations.include?(node.loc.keyword)
        end

        def whitespace_range(node)
          begin_pos      = node.loc.keyword.begin_pos
          current_column = node.loc.keyword.column

          range_between(begin_pos - current_column, begin_pos)
        end

        def access_modifier?(node)
          return true if node.respond_to?(:access_modifier?) && node.access_modifier?

          return true if node.respond_to?(:method_name) &&
                         ALTERNATIVE_ACCESS_MODIFIERS.include?(node.method_name)

          false
        end

        def alignment_location(alignment_node)
          if begin_end_alignment_style == 'start_of_line'
            start_line_range(alignment_node)
          else
            alignment_node.source_range
          end
        end

        def begin_end_alignment_style
          begin_end_alignment_conf = config.for_cop('Layout/BeginEndAlignment')

          begin_end_alignment_conf['Enabled'] && begin_end_alignment_conf['EnforcedStyleAlignWith']
        end
      end
    end
  end
end
