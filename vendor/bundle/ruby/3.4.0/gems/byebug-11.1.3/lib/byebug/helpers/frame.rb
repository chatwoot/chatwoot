# frozen_string_literal: true

module Byebug
  module Helpers
    #
    # Utilities to assist frame navigation
    #
    module FrameHelper
      def switch_to_frame(frame)
        new_frame = index_from_start(frame)
        return frame_err("c_frame") if Frame.new(context, new_frame).c_frame?

        adjust_frame(new_frame)
      end

      def jump_frames(steps)
        adjust_frame(navigate_to_frame(steps))
      end

      private

      def adjust_frame(new_frame)
        return frame_err("too_low") if new_frame >= context.stack_size
        return frame_err("too_high") if new_frame.negative?

        context.frame = new_frame
        processor.prev_line = nil
      end

      def navigate_to_frame(jump_no)
        current_jumps = 0
        current_pos = context.frame.pos

        loop do
          current_pos += direction(jump_no)
          break if out_of_bounds?(current_pos)

          next if Frame.new(context, current_pos).c_frame?

          current_jumps += 1
          break if current_jumps == jump_no.abs
        end

        current_pos
      end

      def out_of_bounds?(pos)
        !(0...context.stack_size).cover?(pos)
      end

      def frame_err(msg)
        errmsg(pr("frame.errors.#{msg}"))
      end

      #
      # @param step [Integer] A positive or negative integer
      #
      # @return [Integer] +1 if step is positive / -1 if negative
      #
      def direction(step)
        step / step.abs
      end

      #
      # Convert a possibly negative index to a positive index from the start
      # of the callstack. -1 is the last position in the stack and so on.
      #
      # @param i [Integer] Integer to be converted in a proper positive index.
      #
      def index_from_start(index)
        index >= 0 ? index : context.stack_size + index
      end
    end
  end
end
