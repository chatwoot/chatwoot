class Captain::Copilot::Actions::Unmute < Captain::Copilot::Actions::BaseAction
  NAME = 'unmute'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Unmute each conversation, which unblocks its contact. Arguments: none, pass an empty object.'.freeze
  ARGUMENTS = { type: 'object', additionalProperties: false, properties: {} }.deep_stringify_keys.freeze

  # The same write as the dashboard's unmute button.
  def perform(conversation)
    return :skipped unless conversation.muted?

    conversation.unmute!
    :applied
  end
end
