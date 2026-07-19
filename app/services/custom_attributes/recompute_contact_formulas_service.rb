class CustomAttributes::RecomputeContactFormulasService
  pattr_initialize [:contact!]

  def perform
    formula_defs = contact.account.custom_attribute_definitions
                          .contact_attribute
                          .where.not(formula: nil)
    return if formula_defs.blank?

    conversations = contact.conversations.select(:id, :custom_attributes)
    attrs = contact.custom_attributes.dup

    formula_defs.each do |definition|
      attrs[definition.attribute_key] = compute(definition, conversations)
    end

    contact.update!(custom_attributes: attrs)
  end

  private

  def compute(definition, conversations)
    formula = definition.formula || {}
    op = formula['op'].to_s
    source_key = formula['source_attribute_key'].to_s
    return nil if source_key.blank?

    values = conversations.filter_map do |conversation|
      raw = conversation.custom_attributes&.[](source_key)
      next if raw.nil? || raw == ''

      Float(raw)
    rescue ArgumentError, TypeError
      nil
    end

    case op
    when 'count'
      values.size
    when 'avg'
      return nil if values.empty?

      (values.sum / values.size).round(2)
    else # sum
      values.sum
    end
  end
end
