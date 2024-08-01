class CustomExceptions::Ticket < CustomExceptions::Base
  attr_reader :message

  def initialize(message)
    super
    @message = message
  end
end
