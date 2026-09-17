# Validate persisted globals before changing their locations. A live continuation
# must not poison the session and prevent even an error response from being saved.
class Captain::Apropos::Workspace < Scheme::Environment
  class Cell < ::Scheme::Environment::Cell
    def initialize(value, validator)
      super(value)
      @validator = validator
    end

    def value=(value)
      @validator.call(value)
      super
    end
  end

  def initialize(parent, &validator)
    super(parent)
    @validator = validator
  end

  def define(name, value)
    raise ::Scheme::Error, 'binding name must be an identifier' unless name.is_a?(Symbol)
    return bindings.fetch(name).value = value if bindings.key?(name)

    @validator.call(value)
    bindings[name] = Cell.new(value, @validator)
  end
end
