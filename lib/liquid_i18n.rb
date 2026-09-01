class I18n::TranslationMissing < StandardError; end
class I18n::TooMuchInterpolation < StandardError; end

module LiquidI18n
  MAX_INTERPOLATIONS = 10

  def t(query)
    translation_key, interpolation_vals = parse_interpolation(query)
    begin
      @context.registers['view'].translate(
        translation_key,
        **interpolation_vals.merge(:raise => !Rails.env.production?)
      )
    rescue StandardError => e
      raise I18n::TranslationMissing, e.message
    end
  end

  def val(base, key, value)
    "#{base}, #{key}: #{value}"
  end

  private

  def parse_interpolation(query)
    params = {}
    depth = 0
    _, translation_key, string_params = /([^,]+)(.*)/.match(query).to_a
    while string_params.present? && string_params.length.positive?
      raise I18n::TooMuchInterpolation, "More than #{MAX_INTERPOLATIONS} interpolation values are not allowed." if depth >= MAX_INTERPOLATIONS

      _, key, val, string_params = /, *([a-zA-z_]+): *([^,]+)(.*)/.match(string_params).to_a
      params[key.to_sym] = val if key.present? && key.length.positive?
      depth += 1
    end
    [translation_key, params]
  end
end
