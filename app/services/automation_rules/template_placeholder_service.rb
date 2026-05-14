class AutomationRules::TemplatePlaceholderService
  # Substitutes `{{namespace.attribute}}` tokens inside a WhatsApp template
  # parameter value at rule-execution time. Tokens that don't match a known
  # attribute (or resolve to nil/empty) are replaced with an empty string so
  # the WhatsApp API never receives a literal placeholder.
  TOKEN_REGEX = /{{\s*([a-z_]+)\.([a-z_]+)\s*}}/i

  def initialize(conversation)
    @conversation = conversation
    @contact = conversation.contact
    @assignee = conversation.assignee
  end

  def substitute(value)
    return value unless value.is_a?(String)

    value.gsub(TOKEN_REGEX) do
      namespace = Regexp.last_match(1).downcase
      attribute = Regexp.last_match(2).downcase
      resolve(namespace, attribute).to_s
    end
  end

  def substitute_processed_params(processed_params)
    return {} if processed_params.blank?

    processed_params.transform_values { |v| substitute(v) }
  end

  private

  def resolve(namespace, attribute)
    case namespace
    when 'contact'
      contact_attribute(attribute)
    when 'conversation'
      conversation_attribute(attribute)
    when 'agent'
      agent_attribute(attribute)
    end
  end

  def contact_attribute(attribute)
    return if @contact.blank?

    case attribute
    when 'name' then @contact.name
    when 'email' then @contact.email
    when 'phone_number' then @contact.phone_number
    when 'identifier' then @contact.identifier
    end
  end

  def conversation_attribute(attribute)
    case attribute
    when 'id' then @conversation.display_id
    when 'display_id' then @conversation.display_id
    end
  end

  def agent_attribute(attribute)
    return if @assignee.blank?

    case attribute
    when 'name' then @assignee.name
    when 'email' then @assignee.email
    end
  end
end
