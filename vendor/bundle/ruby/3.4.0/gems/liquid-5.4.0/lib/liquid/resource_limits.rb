# frozen_string_literal: true

module Liquid
  class ResourceLimits
    attr_accessor :render_length_limit, :render_score_limit, :assign_score_limit
    attr_reader :render_score, :assign_score

    def initialize(limits)
      @render_length_limit = limits[:render_length_limit]
      @render_score_limit  = limits[:render_score_limit]
      @assign_score_limit  = limits[:assign_score_limit]
      reset
    end

    def increment_render_score(amount)
      @render_score += amount
      raise_limits_reached if @render_score_limit && @render_score > @render_score_limit
    end

    def increment_assign_score(amount)
      @assign_score += amount
      raise_limits_reached if @assign_score_limit && @assign_score > @assign_score_limit
    end

    # update either render_length or assign_score based on whether or not the writes are captured
    def increment_write_score(output)
      if (last_captured = @last_capture_length)
        captured = output.bytesize
        increment = captured - last_captured
        @last_capture_length = captured
        increment_assign_score(increment)
      elsif @render_length_limit && output.bytesize > @render_length_limit
        raise_limits_reached
      end
    end

    def raise_limits_reached
      @reached_limit = true
      raise MemoryError, "Memory limits exceeded"
    end

    def reached?
      @reached_limit
    end

    def reset
      @reached_limit = false
      @last_capture_length = nil
      @render_score = @assign_score = 0
    end

    def with_capture
      old_capture_length = @last_capture_length
      begin
        @last_capture_length = 0
        yield
      ensure
        @last_capture_length = old_capture_length
      end
    end
  end
end
