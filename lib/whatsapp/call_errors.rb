module Whatsapp::CallErrors
  class NotRinging < StandardError; end
  class AlreadyAccepted < StandardError; end
  class CallFailed < StandardError; end
  class NoCallPermission < StandardError; end
end
