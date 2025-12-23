module Skiptrace
  class Location
    attr_reader :binding

    def initialize(location, binding)
      @location = location
      @binding = binding
    end

    def absolute_path
      @location.absolute_path
    end

    def base_label
      @location.base_label
    end

    def inspect
      @location.inspect
    end

    def label
      @location.label
    end

    def lineno
      @location.lineno
    end

    def to_s
      @location.to_s
    end
  end
end
