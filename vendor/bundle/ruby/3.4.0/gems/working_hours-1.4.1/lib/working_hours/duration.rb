require 'date'
require 'working_hours/computation'

module WorkingHours
  class Duration

    attr_accessor :value, :kind

    SUPPORTED_KINDS = [:days, :hours, :minutes, :seconds]

    def initialize(value, kind)
      raise ArgumentError.new("Invalid working time unit: #{kind}") unless SUPPORTED_KINDS.include?(kind)
      @value = value
      @kind = kind
    end

    # Computation methods
    def until(time = ::Time.current)
      ::WorkingHours.send("add_#{@kind}", time, -@value)
    end
    alias :ago :until

    def since(time = ::Time.current)
      ::WorkingHours.send("add_#{@kind}", time, @value)
    end
    alias :from_now :since

    # Value object methods
    def -@
      Duration.new(-value, kind)
    end

    def ==(other)
      self.class == other.class and kind == other.kind and value == other.value
    end
    alias :eql? :==

    def hash
      [self.class, kind, value].hash
    end

  end
end
