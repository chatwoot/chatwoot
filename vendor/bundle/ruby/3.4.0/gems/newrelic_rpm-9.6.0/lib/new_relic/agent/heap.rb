# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    # This class implements a min Heap. The first element is always the one with the
    # lowest priority. It is a tree structure that is represented as an array. The
    # relationship between nodes in the tree and indices in the array are as
    # follows:
    #
    # parent_index      = (child_index -  1) / 2
    # left_child_index  = parent_index * 2 + 1
    # right_child_index = parent_index * 2 + 2
    #
    # the root node is at index 0
    # a node is a leaf node when its index >= length / 2
    #

    class Heap
      # @param [Array] items an optional array of items to initialize the heap
      #
      # @param [Callable] priority_fn an optional priority function used to
      #   to compute the priority for an item. If it's not supplied priority
      #   will be computed using Comparable.
      def initialize(items = nil, &priority_fn)
        @items = []
        @priority_fn = priority_fn || ->(x) { x }
        # the following line needs else branch coverage
        items.each { |item| push(item) } if items # rubocop:disable Style/SafeNavigation
      end

      def [](index)
        @items[index]
      end

      def []=(index, value)
        @items[index] = value
      end

      def fix(index)
        parent_index = parent_index_for(index)

        if in_range?(parent_index) && priority(parent_index) > priority(index)
          heapify_up(index)
        else
          child_index = left_child_index_for(index)

          return unless in_range?(child_index)

          if right_sibling_smaller?(child_index)
            child_index += 1
          end

          if priority(child_index) < priority(index)
            heapify_down(index)
          end
        end
      end

      def push(item)
        @items << item
        heapify_up(size - 1)
      end

      alias_method :<<, :push

      def pop
        swap(0, size - 1)
        item = @items.pop
        heapify_down(0)
        item
      end

      def size
        @items.size
      end

      def empty?
        @items.empty?
      end

      def to_a
        @items
      end

      private

      def priority(index)
        @priority_fn.call(@items[index])
      end

      def parent_index_for(child_index)
        (child_index - 1) / 2
      end

      def left_child_index_for(parent_index)
        parent_index * 2 + 1
      end

      def right_sibling_smaller?(lchild_index)
        in_range?(lchild_index + 1) && priority(lchild_index) > priority(lchild_index + 1)
      end

      def in_range?(index)
        index >= 0 && index < size
      end

      def heapify_up(child_index)
        return if child_index == 0

        parent_index = parent_index_for(child_index)

        if priority(child_index) < priority(parent_index)
          swap(child_index, parent_index)
          heapify_up(parent_index)
        end
      end

      def heapify_down(parent_index)
        child_index = left_child_index_for(parent_index)
        return unless in_range?(child_index)

        if right_sibling_smaller?(child_index)
          child_index += 1
        end

        if priority(child_index) < priority(parent_index)
          swap(parent_index, child_index)
          heapify_down(child_index)
        end
      end

      def swap(i, j)
        @items[i], @items[j] = @items[j], @items[i]
      end
    end
  end
end
