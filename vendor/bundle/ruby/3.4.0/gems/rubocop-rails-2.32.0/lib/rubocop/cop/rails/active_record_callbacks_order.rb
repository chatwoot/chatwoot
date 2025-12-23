# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that Active Record callbacks are declared
      # in the order in which they will be executed.
      #
      # @example
      #   # bad
      #   class Person < ApplicationRecord
      #     after_commit :after_commit_callback
      #     before_validation :before_validation_callback
      #   end
      #
      #   # good
      #   class Person < ApplicationRecord
      #     before_validation :before_validation_callback
      #     after_commit :after_commit_callback
      #   end
      #
      class ActiveRecordCallbacksOrder < Base
        extend AutoCorrector

        MSG = '`%<current>s` is supposed to appear before `%<previous>s`.'

        CALLBACKS_IN_ORDER = %i[
          after_initialize
          before_validation
          after_validation
          before_save
          around_save
          before_create
          around_create
          after_create
          before_update
          around_update
          after_update
          before_destroy
          around_destroy
          after_destroy
          after_save
          after_commit
          after_rollback
          after_find
          after_touch
        ].freeze

        CALLBACKS_ORDER_MAP = CALLBACKS_IN_ORDER.each_with_index.to_h.freeze

        def on_class(class_node)
          previous_index = -1
          previous_callback = nil

          defined_callbacks(class_node).each do |node|
            callback = node.method_name
            index = CALLBACKS_ORDER_MAP[callback]

            if index < previous_index
              message = format(MSG, current: callback, previous: previous_callback)
              add_offense(node, message: message) do |corrector|
                autocorrect(corrector, node)
              end
            end
            previous_index = index
            previous_callback = callback
          end
        end

        private

        # Autocorrect by swapping between two nodes autocorrecting them
        def autocorrect(corrector, node)
          previous = node.left_siblings.reverse_each.find do |sibling|
            callback?(sibling)
          end

          current_range = source_range_with_comment(node)
          previous_range = source_range_with_comment(previous)

          corrector.insert_before(previous_range, current_range.source)
          corrector.remove(current_range)
        end

        def defined_callbacks(class_node)
          class_def = class_node.body

          if class_def
            class_def.each_child_node.select { |c| callback?(c) }
          else
            []
          end
        end

        def callback?(node)
          node.send_type? && CALLBACKS_ORDER_MAP.key?(node.method_name)
        end

        def source_range_with_comment(node)
          begin_pos = begin_pos_with_comment(node)
          end_pos = end_position_for(node)

          Parser::Source::Range.new(buffer, begin_pos, end_pos)
        end

        def end_position_for(node)
          end_line = buffer.line_for_position(node.source_range.end_pos)
          buffer.line_range(end_line).end_pos
        end

        def begin_pos_with_comment(node)
          annotation_line = node.first_line - 1
          first_comment = nil

          processed_source.each_comment_in_lines(0..annotation_line).reverse_each do |comment|
            if comment.location.line == annotation_line && !inline_comment?(comment)
              first_comment = comment
              annotation_line -= 1
            end
          end

          start_line_position(first_comment || node)
        end

        def inline_comment?(comment)
          !comment_line?(comment.source_range.source_line)
        end

        def start_line_position(node)
          buffer.line_range(node.loc.line).begin_pos - 1
        end

        def buffer
          processed_source.buffer
        end
      end
    end
  end
end
