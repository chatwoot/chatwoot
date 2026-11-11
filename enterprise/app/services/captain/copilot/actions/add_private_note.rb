class Captain::Copilot::Actions::AddPrivateNote < Captain::Copilot::Actions::BaseAction
  NAME = 'add_private_note'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Add a private note to each conversation, as the agent. Only the team sees it. Arguments: content, the note text. ' \
                'The agent reads the note on the approval card before it is added.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[content],
    properties: { content: { type: 'string', minLength: 1, maxLength: 150_000 } }
  }.deep_stringify_keys.freeze

  # Uses the message builder that notes typed in the dashboard use, so mentions notify agents as they do there.
  def perform(conversation)
    Messages::MessageBuilder.new(@user, conversation, { content: @arguments['content'], private: true }).perform
    :applied
  end

  def card(_ids)
    super.merge(content: @arguments['content'])
  end
end
