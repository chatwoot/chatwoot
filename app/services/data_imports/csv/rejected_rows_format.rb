class DataImports::Csv::RejectedRowsFormat
  VERSION_COLUMN = '__chatwoot_csv_format'.freeze
  VERSION = 'rejected-contacts-v1'.freeze

  def self.generate_line(values)
    # Double literal leading apostrophes so they remain distinct from CSVSafe's escape.
    escaped = values.map { |value| value&.start_with?("'") ? "'#{value}" : value }
    CSVSafe.generate_line(escaped + [VERSION])
  end

  def self.decode_row(fields)
    return fields unless fields.key?(VERSION_COLUMN)

    raise CustomExceptions::DataImport::InvalidCsvError, 'Unsupported rejected contacts CSV format.' unless fields[VERSION_COLUMN] == VERSION

    fields.except(VERSION_COLUMN).transform_values { |value| value&.delete_prefix("'") }
  end
end
