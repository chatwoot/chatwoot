# frozen_string_literal: true

# LLMs often wrap JSON in markdown fences or add a short preamble despite instructions.
module Captain::JsonPayloadExtractor
  module_function

  # Returns a substring suitable for JSON.parse (single JSON object).
  def json_string_from_content(content)
    raw = content.to_s.strip
    return '' if raw.empty?

    unfenced = strip_optional_markdown_fences(raw)
    extract_json_object_string(unfenced)
  end

  def strip_optional_markdown_fences(str)
    if (m = str.match(/```(?:json)?\s*([\s\S]*?)```/im))
      m[1].strip
    else
      str
    end
  end

  def extract_json_object_string(str)
    s = str.strip
    i = s.index('{')
    j = s.rindex('}')
    return s if i.nil? || j.nil? || j < i

    s[i..j]
  end
end
