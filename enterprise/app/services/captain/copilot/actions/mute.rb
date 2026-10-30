class Captain::Copilot::Actions::Mute < Captain::Copilot::Actions::BaseAction
  NAME = 'mute'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = "Mute each conversation. This resolves it and blocks the contact, so the contact's new messages do not notify " \
                'the team in any conversation. Arguments: none, pass an empty object.'.freeze
  ARGUMENTS = { type: 'object', additionalProperties: false, properties: {} }.deep_stringify_keys.freeze

  # The same write as the dashboard's mute button.
  def perform(conversation)
    return :skipped if conversation.muted?

    conversation.mute!
    :applied
  end

  def card(_ids)
    super.merge(warning: 'MUTE')
  end
end
