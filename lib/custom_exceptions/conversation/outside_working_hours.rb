# frozen_string_literal: true

class CustomExceptions::Conversation::OutsideWorkingHours < CustomExceptions::Base
  def message
    I18n.t('errors.conversations.outside_working_hours')
  end

  # `reason` lets the dashboard tell this refusal apart from a takeover, which
  # answers the same 409.
  def to_hash
    { message: message, reason: 'outside_working_hours' }
  end

  def http_status
    409
  end
end
