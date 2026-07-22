class FormulaPreviewService
  pattr_initialize [:definition, :sample_attributes]

  def compute
    return nil if definition.blank?
    return nil unless definition.formula?

    formula = definition.formula || {}
    op = formula['op'].to_s
    source_key = formula['source_attribute_key'].to_s
    return nil if source_key.blank?

    raw = sample_attributes&.[](source_key)
    value = parse_numeric(raw)
    return nil if value.nil?

    apply_op(op, value)
  end

  private

  def apply_op(op, value)
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

    Float(raw.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
