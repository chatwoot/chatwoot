# Service to process Liquid template variables
# Extracted from Liquidable concern to be reusable across different contexts
class Liquid::TemplateVariableProcessorService
  pattr_initialize [:drops!]

  def process_hash(hash)
    return hash unless hash.is_a?(Hash)

    hash.transform_values { |value| process_value(value) }
  end

  def process_value(value)
    case value
    when String
      process_string(value)
    when Hash
      process_hash(value)
    when Array
      value.map { |item| process_value(item) }
    else
      value
    end
  end

  def process_string(string)
    return string if string.blank?

    template = Liquid::Template.parse(string)
    template.render(drops)
  rescue Liquid::Error => e
    Rails.logger.warn "Liquid template processing error: #{e.message}"
    string
  end
end

