class DataImports::Csv::UploadValidator
  MAX_FILE_SIZE = 50.megabytes
  MAX_ROWS = 250_000
  MAX_FIELD_SIZE = 1.megabyte

  def initialize(file)
    @file = file
  end

  def perform
    raise ArgumentError, 'Choose a CSV file.' unless @file.is_a?(ActionDispatch::Http::UploadedFile)
    raise ArgumentError, 'Choose a file with the .csv extension.' unless File.extname(@file.original_filename).casecmp?('.csv')
    raise ArgumentError, 'The CSV file must not be empty.' unless @file.size.positive?
    raise ArgumentError, 'The CSV file must be 50 MiB or smaller.' if @file.size > MAX_FILE_SIZE

    {}
  end
end
