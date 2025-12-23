require "working_hours/duration"

module WorkingHours
  class DurationProxy

    attr_accessor :value

    def initialize(value)
      @value = value
    end

    Duration::SUPPORTED_KINDS.each do |kind|
      define_method kind do
        Duration.new(@value, kind)
      end

      # Singular version
      define_method kind[0..-2] do
        Duration.new(@value, kind)
      end
    end
  end
end
