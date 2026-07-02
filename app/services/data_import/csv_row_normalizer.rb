class DataImport::CsvRowNormalizer
  DOCUMENT_NUMBER_HEADERS = %w[
    document_number
    documento
    numero_documento
    num_documento
    cedula
    dni
    ruc
    nit
    id_document
    document
  ].freeze

  def self.normalize(row)
    row.to_h.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |(key, value), normalized|
      normalized[normalize_key(key)] = value
    end
  end

  def self.normalize_key(key)
    raw = key.to_s.delete_prefix("\uFEFF").strip.downcase
    normalized = raw.tr(':', '_').gsub(/[\s-]+/, '_')
    return 'document_number' if DOCUMENT_NUMBER_HEADERS.include?(normalized)

    normalized
  end
end
