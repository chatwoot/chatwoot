class Captain::CustomerContext
  MAX_CHARACTERS = 4_000
  ATTRIBUTE_MODELS = %w[contact_attribute conversation_attribute].freeze

  pattr_initialize [:conversation!]

  # Shares only the custom attributes the account has defined, under the names the admin sees.
  # Names are not unique, so each attribute is its own entry.
  def attributes
    @remaining = MAX_CHARACTERS
    {
      contact: section('contact_attribute', conversation.contact.custom_attributes),
      conversation: section('conversation_attribute', conversation.custom_attributes)
    }
  end

  private

  def section(attribute_model, values)
    definitions.select { |definition| definition.attribute_model == attribute_model }.each_with_object([]) do |definition, section|
      value = values[definition.attribute_key]
      size = definition.attribute_display_name.length + value.to_s.length
      next if value.nil? || value == '' || size > @remaining

      @remaining -= size
      section << { name: definition.attribute_display_name, value: value }
    end
  end

  def definitions
    @definitions ||= conversation.account.custom_attribute_definitions.where(attribute_model: ATTRIBUTE_MODELS).order(:id).to_a
  end
end
