class Captain::Apropos::CallError < Captain::Apropos::Error
  attr_reader :primitive

  def initialize(primitive, cause)
    @primitive = primitive
    super("#{primitive}: #{cause.message}")
  end
end
