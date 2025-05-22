module JsonHelper
  def extract_json_from_code_block(code_block)
    # Remove the code block markers
    code_block = code_block.gsub(/\A```json\s*|\s*```$/, '').strip

    # Parse the JSON string
    begin
      JSON.parse(code_block)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON: #{e.message}")
      nil
    end
  end
end
