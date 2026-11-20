# frozen_string_literal: true

# Raised when the channel refuses to delete a message, so it is kept in Chatwoot as well
class CustomExceptions::ChannelMessageDeleteFailed < CustomExceptions::Base
  def message
    @data[:message]
  end

  def to_hash
    { error: message }
  end

  def http_status
    :unprocessable_entity
  end
end
