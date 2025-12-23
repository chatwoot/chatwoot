# frozen_string_literal: true

module Stripe
  # Represents hierarchical context for Stripe API operations.
  #
  # This class is immutable - all methods return new instances rather than
  # modifying the existing instance. It provides utilities for building
  # context hierarchies and converting to/from string representations.
  class StripeContext
    include Comparable

    attr_reader :segments

    # Creates a new StripeContext with the given segments.
    def initialize(segments = nil)
      @segments = (segments || []).map(&:to_s).freeze
    end

    # Parses a context string into a StripeContext instance.
    def self.parse(context_str)
      return new if context_str.nil? || context_str.empty?

      new(context_str.split("/"))
    end

    # Creates a new StripeContext with an additional segment appended.
    def push(segment)
      segment_str = segment.to_s.strip
      raise ArgumentError, "Segment cannot be empty or whitespace" if segment_str.empty?

      new_segments = @segments + [segment_str]
      self.class.new(new_segments)
    end

    # Creates a new StripeContext with the last segment removed.
    # If there are no segments, returns a new empty StripeContext.
    def pop
      raise IndexError, "No segments to pop" if @segments.empty?

      new_segments = @segments[0...-1]
      self.class.new(new_segments)
    end

    # Converts this context to its string representation.
    def to_s
      @segments.join("/")
    end

    # Checks equality with another StripeContext.
    def ==(other)
      other.is_a?(StripeContext) && @segments == other.segments
    end

    # Alias for == to support eql? method
    alias eql? ==

    # Returns a human-readable representation for debugging.
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} segments=#{@segments.inspect}>"
    end

    # Returns true if the context has no segments.
    # @return [Boolean] true if empty, false otherwise
    def empty?
      @segments.empty?
    end
  end
end
