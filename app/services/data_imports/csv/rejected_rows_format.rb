class DataImports::Csv::RejectedRowsFormat
  VERSION_COLUMN = '__chatwoot_csv_format'.freeze
  VERSION = 'rejected-contacts-v1'.freeze

  def self.generate_line(values)
    CSVSafe.generate_line(escape(values) + [VERSION])
  end

  def self.generate_headers(headers)
    CSVSafe.generate_line(escape(headers) + [VERSION_COLUMN])
  end

  def self.decode_headers(headers)
    return headers unless headers.include?(VERSION_COLUMN)

    headers.excluding(VERSION_COLUMN).map { |header| header.delete_prefix("'") }
  end

  def self.decode_row(fields)
    return fields unless fields.key?(VERSION_COLUMN)

    raise CustomExceptions::DataImport::InvalidCsvError, 'Unsupported rejected contacts CSV format.' unless fields[VERSION_COLUMN] == VERSION

    fields.except(VERSION_COLUMN).transform_keys { |key| key.delete_prefix("'") }.transform_values { |value| value&.delete_prefix("'") }
  end

  def self.escape(values)
    # Double literal leading apostrophes so they remain distinct from CSVSafe's escape.
    values.map { |value| value&.start_with?("'") ? "'#{value}" : value }
  end
  private_class_method :escape
end
