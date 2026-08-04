# frozen_string_literal: true

class CustomExceptions::Whatsapp::InvalidInteractivePayload < CustomExceptions::Base
  def message
    @data
  end
end
