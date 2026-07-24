class CustomAttributes::RecomputeConversationFormulasService
  pattr_initialize [:conversation!]

  def perform
    formula_defs = conversation.account.custom_attribute_definitions
                                .conversation_attribute
                                .where.not(formula: nil)
    return if formula_defs.blank?

    attrs = (conversation.custom_attributes || {}).dup

    formula_defs.each do |definition|
      attrs[definition.attribute_key] = compute(definition, conversation)
    end

    return if attrs == (conversation.custom_attributes || {})

    # Quiet write: skip callbacks so formula persistence does not re-enqueue
    # account-wide recompute jobs or flood ActionCable / EventDispatcher.
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(custom_attributes: attrs, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  # For conversation_attribute formulas, the source can be:
  #  - 'self' (the conversation itself) - default
  #  - 'messages' (aggregate over messages)
  # Currently we only support self.
  def compute(definition, _target)
    formula = definition.formula || {}
    op = formula['op'].to_s
    source_key = formula['source_attribute_key'].to_s
    return nil if source_key.blank?

    raw = conversation.custom_attributes&.[](source_key)
    value = CustomAttributes::NumericParser.parse(raw)
    return nil if value.nil?

    case op
    when 'count'
      value.zero? ? 0 : 1
    when 'avg', 'sum'
      value
    else
      value
    end
  end
end
