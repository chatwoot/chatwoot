class Exception
  def binding_locations
    @binding_locations ||= Skiptrace::BindingLocations.new(backtrace_locations, bindings)
  end
end
