# frozen_string_literal: true

class CustomExceptions::Whatsapp::MediaUploadError < CustomExceptions::Base
  def message
    @data
  end
end
