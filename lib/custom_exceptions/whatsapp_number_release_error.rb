class CustomExceptions::WhatsappNumberReleaseError < CustomExceptions::Base
  def message
    I18n.t("errors.whatsapp.release_number.#{@data[:reason]}", meta_message: @data[:meta_message])
  end

  def http_status
    :unprocessable_entity
  end
end
