class Captain::Copilot::Actions::SendReply < Captain::Copilot::Actions::BaseAction
  NAME = 'send_reply'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Send a reply to the customer in each conversation, as the agent. Arguments: content, the reply text exactly as the agent ' \
                'wrote it. Never write, translate or edit the reply yourself. When the agent has not given the text, ask for it.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[content],
    properties: { content: { type: 'string', minLength: 1, maxLength: 150_000 } }
  }.deep_stringify_keys.freeze
  REPEATABLE = false

  # The agent approved a reply to conversations as they were when it was proposed, so a reply is not sent to one that has
  # since been resolved, reopened or snoozed.
  def proposal_states(ids)
    @account.conversations.where(id: ids).pluck(:id, :status).to_h.transform_keys(&:to_s)
  end

  # Uses the message builder that agent replies and macros use, so delivery, events and activity work as they do for a reply
  # typed in the dashboard.
  def perform(conversation)
    proposed_status = @proposal_states.fetch(conversation.id.to_s)
    if conversation.status != proposed_status
      raise Captain::Copilot::ActionNotApplicableError,
            "The conversation was #{proposed_status} when the reply was proposed and is now #{conversation.status}, so the reply was not sent"
    end
    unless conversation.can_reply?
      raise Captain::Copilot::ActionNotApplicableError,
            "The channel's reply window has closed, so the reply was not sent"
    end

    Messages::MessageBuilder.new(@user, conversation, { content: @arguments['content'], private: false }).perform
    'applied'
  end
end
