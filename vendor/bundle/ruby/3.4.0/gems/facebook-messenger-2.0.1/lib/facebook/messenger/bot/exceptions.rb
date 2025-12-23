module Facebook
  module Messenger
    module Bot
      # Base Facebook Messenger send API exception.
      class SendError < Facebook::Messenger::FacebookError; end

      class AccessTokenError < SendError; end
      class AccountLinkingError < SendError; end
      class BadParameterError < SendError; end
      class InternalError < SendError; end
      class LimitError < SendError; end
      class PermissionError < SendError; end
    end
  end
end
