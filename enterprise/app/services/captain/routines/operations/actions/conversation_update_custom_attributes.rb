class Captain::Routines::Operations::Actions::ConversationUpdateCustomAttributes < Captain::Routines::Operations::Action
  configure(
    name: 'conversations.update_custom_attributes', effect: 'internal_write',
    description: 'Update configured custom attributes on one conversation.',
    arguments: {
      conversation_id: 'conversation ID or reference', attributes: 'object containing custom attribute names and values'
    },
    required: %w[conversation_id attributes]
  )

  def execute(conversation_id:, attributes:)
    conversation = conversation!(conversation_id)
    normalized_attributes = normalize_attributes(attributes)
    conversation.update!(custom_attributes: conversation.custom_attributes.merge(normalized_attributes))
    conversation_data(conversation.reload)
  end

  private

  def normalize_attributes(attributes)
    definitions = account.custom_attribute_definitions.with_attribute_model('conversation_attribute')
    attributes.to_h do |name, value|
      definition = definitions.where(attribute_key: name.to_s)
                              .or(definitions.where('LOWER(attribute_display_name) = ?', name.to_s.downcase)).sole
      [definition.attribute_key, value]
    end
  end
end
