class Captain::Apropos::CallError < Captain::Apropos::Error
  attr_reader :primitive

  def initialize(primitive, cause)
    @primitive = primitive
    super("#{primitive}: #{cause.message}")
    with_feedback(*cause.evidence, context: cause.context) if cause.is_a?(Captain::Apropos::Error)
  end
end
