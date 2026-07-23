class CustomAttributes::RecomputeCompanyFormulasService
  pattr_initialize [:company!]

  def perform
    formula_defs = company.account.custom_attribute_definitions
                           .company_attribute
                           .where.not(formula: nil)
    return if formula_defs.blank?

    # Companies don't have child records we can aggregate over in the same
    # way as conversations -> contacts. For now we only support
    # self-referential formulas (sum/avg of the company's own custom attribute).
    attrs = (company.custom_attributes || {}).dup

    formula_defs.each do |definition|
      attrs[definition.attribute_key] = compute(definition, company)
    end

    return if attrs == (company.custom_attributes || {})

    # Quiet write: skip callbacks so formula persistence does not re-enqueue
    # account-wide recompute jobs or flood ActionCable / EventDispatcher.
    # rubocop:disable Rails/SkipsModelValidations
    company.update_columns(custom_attributes: attrs, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def compute(definition, _target)
    formula = definition.formula || {}
    op = formula['op'].to_s
    source_key = formula['source_attribute_key'].to_s
    return nil if source_key.blank?

    raw = company.custom_attributes&.[](source_key)
    value = parse_numeric(raw)
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

  def parse_numeric(raw)
    return nil if raw.nil? || raw == ''

    Float(raw)
  rescue ArgumentError, TypeError
    nil
  end
end
