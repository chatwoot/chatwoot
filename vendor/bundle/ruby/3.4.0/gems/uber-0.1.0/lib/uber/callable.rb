module Uber
  # Include this module into a class or extend an object to mark it as callable.
  # E.g., in a dynamic option in Options::Value it will be treated like a Proc object
  # and invoked with +#call+.
  module Callable
  end
end