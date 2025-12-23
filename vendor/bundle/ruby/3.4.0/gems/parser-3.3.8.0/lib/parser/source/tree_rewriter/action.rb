# frozen_string_literal: true

module Parser
  module Source
    ##
    # @api private
    #
    # Actions are arranged in a tree and get combined so that:
    # 
    # * Children are strictly contained by their parent
    # * Siblings are all disjointed from one another and ordered
    # * Only actions with `replacement == nil` may have children
    #
    class TreeRewriter::Action
      attr_reader :range, :replacement, :insert_before, :insert_after

      def initialize(range, enforcer,
           insert_before: '',
           replacement: nil,
           insert_after: '',
           children: []
        )
        @range, @enforcer, @children, @insert_before, @replacement, @insert_after =
          range, enforcer, children.freeze, insert_before.freeze, replacement, insert_after.freeze

        freeze
      end

      def combine(action)
        return self if action.empty? # Ignore empty action
        do_combine(action)
      end

      def empty?
        @insert_before.empty? &&
          @insert_after.empty? &&
          @children.empty? &&
          (@replacement == nil || (@replacement.empty? && @range.empty?))
      end

      def ordered_replacements
        reps = []
        reps << [@range.begin, @insert_before] unless @insert_before.empty?
        reps << [@range, @replacement] if @replacement
        reps.concat(@children.flat_map(&:ordered_replacements))
        reps << [@range.end, @insert_after] unless @insert_after.empty?
        reps
      end

      def nested_actions
        actions = []
        actions << [:wrap, @range, @insert_before, @insert_after] if !@insert_before.empty? ||
                                                                     !@insert_after.empty?
        actions << [:replace, @range, @replacement] if @replacement
        actions.concat(@children.flat_map(&:nested_actions))
      end

      def insertion?
        !insert_before.empty? || !insert_after.empty? || (replacement && !replacement.empty?)
      end

      ##
      # A root action has its range set to the whole source range, even
      # though it typically does not act on that range.
      # This method returns the action as if it was a child action with
      # its range contracted.
      # @return [Action]
      def contract
        raise 'Empty actions can not be contracted' if empty?
        return self if insertion?
        range = @range.with(
          begin_pos: children.first.range.begin_pos,
          end_pos: children.last.range.end_pos,
        )
        with(range: range)
      end

      ##
      # @return [Action] that has been moved to the given source_buffer and with the given offset
      # No check is done on validity of resulting range.
      def moved(source_buffer, offset)
        moved_range = ::Parser::Source::Range.new(
          source_buffer,
          @range.begin_pos + offset,
          @range.end_pos + offset
        )
        with(
          range: moved_range,
          children: children.map { |child| child.moved(source_buffer, offset) }
        )
      end

      protected

      attr_reader :children

      def with(range: @range, enforcer: @enforcer, children: @children, insert_before: @insert_before, replacement: @replacement, insert_after: @insert_after)
        children = swallow(children) if replacement
        self.class.new(range, enforcer, children: children, insert_before: insert_before, replacement: replacement, insert_after: insert_after)
      end

      # Assumes range.contains?(action.range) && action.children.empty?
      def do_combine(action)
        if action.range == @range
          merge(action)
        else
          place_in_hierarchy(action)
        end
      end

      def place_in_hierarchy(action)
        family = analyse_hierarchy(action)

        if family[:fusible]
          fuse_deletions(action, family[:fusible], [*family[:sibbling_left], *family[:child], *family[:sibbling_right]])
        else
          extra_sibbling = if family[:parent]  # action should be a descendant of one of the children
            family[:parent].do_combine(action)
          elsif family[:child]                 # or it should become the parent of some of the children,
            action.with(children: family[:child], enforcer: @enforcer)
              .combine_children(action.children)
          else                                 # or else it should become an additional child
            action
          end
          with(children: [*family[:sibbling_left], extra_sibbling, *family[:sibbling_right]])
        end
      end

      # Assumes `more_children` all contained within `@range`
      def combine_children(more_children)
        more_children.inject(self) do |parent, new_child|
          parent.place_in_hierarchy(new_child)
        end
      end

      def fuse_deletions(action, fusible, other_sibblings)
        without_fusible = with(children: other_sibblings)
        fused_range = [action, *fusible].map(&:range).inject(:join)
        fused_deletion = action.with(range: fused_range)
        without_fusible.do_combine(fused_deletion)
      end

      # Similar to @children.bsearch_index || size
      # except allows for a starting point
      # and `bsearch_index` is only Ruby 2.3+
      def bsearch_child_index(from = 0)
        size = @children.size
        (from...size).bsearch { |i| yield @children[i] } || size
      end

      # Returns the children in a hierarchy with respect to `action`:
      #   :sibbling_left, sibbling_right (for those that are disjoint from `action`)
      #   :parent (in case one of our children contains `action`)
      #   :child (in case `action` strictly contains some of our children)
      #   :fusible (in case `action` overlaps some children but they can be fused in one deletion)
      #   or raises a `CloberingError`
      # In case a child has equal range to `action`, it is returned as `:parent`
      # Reminder: an empty range 1...1 is considered disjoint from 1...10
      def analyse_hierarchy(action)
        r = action.range
        # left_index is the index of the first child that isn't completely to the left of action
        left_index = bsearch_child_index { |child| child.range.end_pos > r.begin_pos }
        # right_index is the index of the first child that is completely on the right of action
        start = left_index == 0 ? 0 : left_index - 1  # See "corner case" below for reason of -1
        right_index = bsearch_child_index(start) { |child| child.range.begin_pos >= r.end_pos }
        center = right_index - left_index
        case center
        when 0
          # All children are disjoint from action, nothing else to do
        when -1
          # Corner case: if a child has empty range == action's range
          # then it will appear to be both disjoint and to the left of action,
          # as well as disjoint and to the right of action.
          # Since ranges are equal, we return it as parent
          left_index -= 1  # Fix indices, as otherwise this child would be
          right_index += 1 # considered as a sibbling (both left and right!)
          parent = @children[left_index]
        else
          overlap_left = @children[left_index].range.begin_pos <=> r.begin_pos
          overlap_right = @children[right_index-1].range.end_pos <=> r.end_pos

          # For one child to be the parent of action, we must have:
          if center == 1 && overlap_left <= 0 && overlap_right >= 0
            parent = @children[left_index]
          else
            # Otherwise consider all non disjoint elements (center) to be contained...
            contained = @children[left_index...right_index]
            fusible = check_fusible(action,
              (contained.shift if overlap_left < 0),  # ... but check first and last one
              (contained.pop if overlap_right > 0)    # ... for overlaps
            )
          end
        end

        {
          parent: parent,
          sibbling_left: @children[0...left_index],
          sibbling_right: @children[right_index...@children.size],
          fusible: fusible,
          child: contained,
        }
      end

      # @param [Array(Action | nil)] fusible
      def check_fusible(action, *fusible)
        fusible.compact!
        return if fusible.empty?
        fusible.each do |child|
          kind = action.insertion? || child.insertion? ? :crossing_insertions : :crossing_deletions
          @enforcer.call(kind) { {range: action.range, conflict: child.range} }
        end
        fusible
      end

      # Assumes action.range == range && action.children.empty?
      def merge(action)
        call_enforcer_for_merge(action)
        with(
          insert_before: "#{action.insert_before}#{insert_before}",
          replacement: action.replacement || @replacement,
          insert_after: "#{insert_after}#{action.insert_after}",
        ).combine_children(action.children)
      end

      def call_enforcer_for_merge(action)
        @enforcer.call(:different_replacements) do
          if @replacement && action.replacement && @replacement != action.replacement
            {range: @range, replacement: action.replacement, other_replacement: @replacement}
          end
        end
      end

      def swallow(children)
        @enforcer.call(:swallowed_insertions) do
          insertions = children.select(&:insertion?)

          {range: @range, conflict: insertions.map(&:range)} unless insertions.empty?
        end
        []
      end
    end
  end
end
