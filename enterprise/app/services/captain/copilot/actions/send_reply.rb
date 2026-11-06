class Captain::Copilot::Actions::SendReply < Captain::Copilot::Actions::BaseAction
  NAME = 'send_reply'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Send a reply to the customer in each conversation, as the agent. Every conversation gets the same text. ' \
                'Arguments: content, the reply text. The agent reads the reply on the approval card before it is sent.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[content],
    properties: { content: { type: 'string', minLength: 1, maxLength: 150_000 } }
  }.deep_stringify_keys.freeze

  # The agent approved a reply to conversations as they were when it was proposed, so a reply is not sent to one that has
  # since been resolved, reopened or snoozed. The time of the last status change also catches a status that changed back,
  # such as a conversation resolved and then reopened by the customer.
  def proposal_values(ids)
    @account.conversations.where(id: ids).pluck(:id, :status, :status_changed_at)
            .to_h { |id, status, changed_at| [id.to_s, [status, changed_at&.iso8601(6)]] }
  end

  # Uses the message builder that agent replies use, so delivery, events and activity work as they do for a reply typed in
  # the dashboard. The message is saved with its item, and delivery starts after that commit, so a retry never sends twice.
  def perform(conversation)
    proposed_status, proposed_change = @proposal_values.fetch(conversation.id.to_s)
    if [conversation.status, conversation.status_changed_at&.iso8601(6)] != [proposed_status, proposed_change]
      raise Captain::Copilot::ActionNotApplicableError,
            "The conversation was #{proposed_status} when the reply was proposed and its status has changed since, so the reply was not sent"
    end
    unless conversation.can_reply?
      raise Captain::Copilot::ActionNotApplicableError,
            "The channel's reply window has closed, so the reply was not sent"
    end

    Messages::MessageBuilder.new(@user, conversation, { content: @arguments['content'], private: false }).perform
    :applied
  end

  def card(_ids)
    super.merge(content: @arguments['content'], warning: 'SEND_REPLY')
  end
end
