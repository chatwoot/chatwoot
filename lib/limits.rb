module Limits
  BULK_ACTIONS_LIMIT = 100
  BULK_EXTERNAL_HTTP_CALLS_LIMIT = 25
  URL_LENGTH_LIMIT = 2048 # https://stackoverflow.com/questions/417142
  OUT_OF_OFFICE_MESSAGE_MAX_LENGTH = 10_000
  GREETING_MESSAGE_MAX_LENGTH = 10_000

  def self.conversation_message_per_minute_limit
    ENV.fetch('CONVERSATION_MESSAGE_PER_MINUTE_LIMIT', '200').to_i
  end
end
