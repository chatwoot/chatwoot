class Whatsapp::InteractiveMessages::EligibilityError < StandardError
  attr_reader :reason

  def initialize(reason)
    @reason = reason
    super(reason)
  end
end
