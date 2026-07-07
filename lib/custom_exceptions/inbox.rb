# frozen_string_literal: true

module CustomExceptions::Inbox
  class LimitExceeded < CustomExceptions::Base
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
end
