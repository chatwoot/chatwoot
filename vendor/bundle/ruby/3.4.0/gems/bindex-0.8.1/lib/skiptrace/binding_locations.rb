module Skiptrace
  class BindingLocations < BasicObject
    def initialize(locations, bindings)
      @locations = locations
      @bindings = bindings
      @cached_locations = {}
    end

    private

    def cached_location(location)
      @cached_locations[location.to_s] ||= Location.new(location, guess_binding_around(location))
    end

    def guess_binding_around(location)
      location && @bindings.find do |binding|
        binding.source_location == [location.path, location.lineno]
      end
    end

    def method_missing(name, *args, &block)
      case maybe_location = @locations.public_send(name, *args, &block)
      when ::Thread::Backtrace::Location
        cached_location(maybe_location)
      else
        maybe_location
      end
    end

    def respond_to_missing?(name, include_all = false)
      @locations.respond_to?(name, include_all)
    end
  end
end
