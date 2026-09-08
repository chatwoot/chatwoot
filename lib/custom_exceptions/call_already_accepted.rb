# frozen_string_literal: true

class CustomExceptions::CallAlreadyAccepted < CustomExceptions::Base
  def message
    I18n.t('errors.voice.call_already_accepted', agent_name: @data[:agent_name])
  end

  def http_status
    409
  end
end
