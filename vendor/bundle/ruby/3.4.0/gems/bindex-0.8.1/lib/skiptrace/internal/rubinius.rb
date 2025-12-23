module Skiptrace
  module Rubinius
    # Filters internal Rubinius locations.
    #
    # There are a couple of reasons why we wanna filter out the locations.
    #
    # * ::Kernel.raise, is implemented in Ruby for Rubinius. We don't wanna
    #   have the frame for it to align with the CRuby and JRuby implementations.
    #
    # * For internal methods location variables can be nil. We can't create a
    #   bindings for them.
    #
    # * Bindings from the current file are considered internal and ignored.
    #
    # We do that all that so we can align the bindings with the backtraces
    # entries.
    class InternalLocationFilter
      def initialize(locations)
        @locations = locations
      end

      def filter
        @locations.reject do |location|
          location.file.start_with?('kernel/delta/kernel.rb') ||
            location.file == __FILE__ ||
            location.variables.nil?
        end
      end
    end
  end
end

# Gets the current bindings for all available Ruby frames.
#
# Filters the internal Rubinius and Skiptrace frames.
def Skiptrace.current_bindings
  locations = ::Rubinius::VM.backtrace(1, true)

  Skiptrace::Rubinius::InternalLocationFilter.new(locations).filter.map do |location|
    Binding.setup(
      location.variables,
      location.variables.method,
      location.constant_scope,
      location.variables.self,
      location
    )
  end
end

::Exception.class_eval do
  def bindings
    @bindings || []
  end
end

::Rubinius.singleton_class.class_eval do
  raise_exception = instance_method(:raise_exception)

  define_method(:raise_exception) do |exc|
    if exc.bindings.empty?
      exc.instance_variable_set(:@bindings, Skiptrace.current_bindings)
    end

    raise_exception.bind(self).call(exc)
  end
end
