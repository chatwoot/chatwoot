class Captain::Routines::AgentTools::UpdateCurrentConversationAttributes < Captain::Routines::AgentTools::Base
  description 'Update configured custom attributes on the current conversation'
  params(
    type: 'object',
    properties: {
      attributes: { type: 'object', additionalProperties: true }
    },
    required: ['attributes'],
    additionalProperties: false
  )

  def name = 'update_current_conversation_attributes'

  def perform(tool_context, attributes:)
    perform_operation(
      tool_context,
      'conversations.update_custom_attributes',
      conversation_id: current_conversation_id(tool_context),
      attributes: attributes
    )
  end
end
