module JsonHelper
  def extract_json_from_code_block(code_block)
    # Remove any code block markers (```json, ```) at the start/end, with optional whitespace/newlines
    code_block = code_block.to_s
                           .gsub(/\A\s*```json\s*\n?/m, '')
                           .gsub(/\A\s*```\s*\n?/m, '')
                           .gsub(/\s*```\s*\z/m, '')
                           .strip

    # Parse the JSON string
    begin
      JSON.parse(code_block)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse JSON: #{e.message}")
      {
        'message': 'Permintaan pelanggan',
        'response': "Ups! Sepertinya ada gangguan kecil dari sisi sistem saya 😅\n\nJangan khawatir, saya masih ingat percakapan kita. Silakan ulangi pertanyaan terakhir Anda, dan saya akan pastikan memberikan jawaban yang tepat! 💪",
        'is_handover_human': false
      }
    end
  end
end
