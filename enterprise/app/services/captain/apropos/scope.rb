class Captain::Apropos::Scope
  UNINITIALIZED = Object.new.freeze
  attr_accessor :values, :parent

  def initialize(values = {}, parent = nil)
    @values = values
    @parent = parent
  end

  def key?(name)
    values.key?(name) || parent&.key?(name)
  end

  def [](name)
    value = values.key?(name) ? values.fetch(name) : parent&.[](name)
    raise Captain::Apropos::Error, "Binding used before initialization: #{name}" if value.equal?(UNINITIALIZED)

    value
  end

  def []=(name, value)
    values[name] = value
  end
end
