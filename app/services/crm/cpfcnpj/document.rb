class Crm::Cpfcnpj::Document
  CPF_LENGTH = 11
  CNPJ_LENGTH = 14

  # Weights used by the modulo 11 check digit routine for the CNPJ.
  # See https://www.cpfcnpj.com.br/dev/ for the document formats.
  CNPJ_FIRST_WEIGHTS = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2].freeze
  CNPJ_SECOND_WEIGHTS = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2].freeze

  class << self
    def normalize(raw)
      raw.to_s.gsub(/[^0-9A-Za-z]/, '').upcase
    end

    def type(raw)
      value = normalize(raw)
      return :cpf if cpf?(value)
      return :cnpj if cnpj?(value)

      nil
    end

    def valid?(raw)
      !type(raw).nil?
    end

    # Reads the document from the configured custom attribute and falls back to
    # the contact identifier. Returns the normalized value only when it is valid.
    def extract_from(contact, attribute_key)
      raw = contact.custom_attributes.to_h[attribute_key]
      raw = contact.identifier if raw.blank?
      value = normalize(raw)
      valid?(value) ? value : nil
    end

    private

    def cpf?(value)
      return false unless value.length == CPF_LENGTH
      return false unless value.match?(/\A\d{11}\z/)
      return false if value.chars.uniq.length == 1

      digits = value.chars.map(&:to_i)
      digits[9] == cpf_check_digit(digits, 9) && digits[10] == cpf_check_digit(digits, 10)
    end

    def cpf_check_digit(digits, position)
      weight = position + 1
      sum = (0...position).sum { |index| digits[index] * (weight - index) }
      remainder = (sum * 10) % 11
      remainder >= 10 ? 0 : remainder
    end

    # The first twelve characters may be alphanumeric; the two check digits are
    # always numeric. Each character contributes its ord value minus 48.
    def cnpj?(value)
      return false unless value.length == CNPJ_LENGTH
      return false unless value.match?(/\A[0-9A-Z]{12}\d{2}\z/)
      return false if value.chars.uniq.length == 1

      values = value.chars.map { |char| char.ord - 48 }
      values[12] == cnpj_check_digit(values, CNPJ_FIRST_WEIGHTS) &&
        values[13] == cnpj_check_digit(values, CNPJ_SECOND_WEIGHTS)
    end

    def cnpj_check_digit(values, weights)
      sum = weights.each_with_index.sum { |weight, index| values[index] * weight }
      remainder = sum % 11
      remainder < 2 ? 0 : 11 - remainder
    end
  end
end
