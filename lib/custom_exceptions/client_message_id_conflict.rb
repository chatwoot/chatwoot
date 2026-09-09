# frozen_string_literal: true

class CustomExceptions::ClientMessageIdConflict < CustomExceptions::Base
  def message
    I18n.t('errors.message.client_message_id_conflict', client_message_id: @data[:client_message_id])
  end

  def http_status
    409
  end
end
