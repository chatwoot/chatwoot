# frozen_string_literal: true

class CustomExceptions::Inbox::LimitExceeded < CustomExceptions::Base
  def message
    'Account limit exceeded. Upgrade to a higher plan'
  end

  def to_hash
    { error: message }
  end

  def http_status
    :payment_required
  end
end
