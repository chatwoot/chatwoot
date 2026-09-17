class Scheme::Environment
  Cell = Struct.new(:value)

  def initialize(parent = nil)
    @parent = parent
    @bindings = {}
  end

  def define(name, value)
    raise Scheme::Error, 'binding name must be an identifier' unless name.is_a?(Symbol)

    if @bindings.key?(name)
      @bindings[name].value = value
    else
      @bindings[name] = Cell.new(value)
    end
  end

  def cell(name)
    @bindings[name] || @parent&.cell(name)
  end

  def get(name)
    binding = cell(name)
    raise Scheme::Error, "unbound identifier: #{name}" unless binding
    raise Scheme::Error, "binding used before initialization: #{name}" if binding.value.equal?(Scheme::UNINITIALIZED)

    binding.value
  end

  def set(name, value)
    binding = cell(name)
    raise Scheme::Error, "cannot set unbound identifier: #{name}" unless binding

    binding.value = value
  end
end
