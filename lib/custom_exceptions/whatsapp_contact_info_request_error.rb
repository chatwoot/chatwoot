class CustomExceptions::WhatsappContactInfoRequestError < CustomExceptions::Base
  def message
    I18n.t("errors.whatsapp.contact_info_request.#{@data[:reason]}")
  end

  def http_status
    :unprocessable_entity
  end
end
