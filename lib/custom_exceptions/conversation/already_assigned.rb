# frozen_string_literal: true

class CustomExceptions::Conversation::AlreadyAssigned < CustomExceptions::Base
  def message
    I18n.t('errors.conversations.already_assigned', agent_name: @data[:agent_name])
  end

  # `agent_name` travels next to the message so the dashboard can build the
  # notice in the agent's own locale instead of echoing a server-side string.
  def to_hash
    { message: message, agent_name: @data[:agent_name] }
  end

  def http_status
    409
  end
end
