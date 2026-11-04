require 'csv'

class DataImports::Csv::Reader
  CHUNK_SIZE = 64.kilobytes
  attr_reader :headers

  def initialize(attachment)
    @attachment = attachment
  end

  def each
    return enum_for(:each) unless block_given?

    @attachment.open do |source|
      Tempfile.create(['contacts-utf8', '.csv']) do |file|
        transcode(source, file)
        csv = CSV.new(file, headers: true, skip_blanks: true, max_field_size: DataImports::Csv::UploadValidator::MAX_FIELD_SIZE)
        row = csv.shift
        @headers = csv.headers
        validate_headers!
        raise CustomExceptions::DataImport::InvalidCsvError, 'The CSV must contain at least one contact row.' unless row

        number = 0
        while row
          number += 1
          validate_row!(row, number)
          yield row.to_h, number
          row = csv.shift
        end
      end
    end
  end

  private

  def transcode(source, target)
    converter = Encoding::Converter.new('UTF-8', 'UTF-16LE', invalid: :replace, undef: :replace, replace: '')
    first = true
    while (chunk = source.read(CHUNK_SIZE))
      output = converter.convert(chunk).encode('UTF-8')
      output = output.delete_prefix("\uFEFF") if first
      first = false
      target.write(output)
    end
    target.write(converter.finish.encode('UTF-8'))
    target.rewind
  end

  def validate_headers!
    unless @headers.is_a?(Array) && @headers.all?(&:present?) && @headers.uniq == @headers
      raise CustomExceptions::DataImport::InvalidCsvError, 'CSV column names must be present and unique.'
    end
    return if @headers.intersect?(%w[name email identifier phone_number])

    raise CustomExceptions::DataImport::InvalidCsvError, 'Include a name, email, identifier, or phone_number column.'
  end

  def validate_row!(row, number)
    if number > DataImports::Csv::UploadValidator::MAX_ROWS
      raise CustomExceptions::DataImport::InvalidCsvError,
            'The CSV exceeds the 250,000 row limit.'
    end
    raise CustomExceptions::DataImport::InvalidCsvError, "Record #{number} has more values than column names." if row.headers.include?(nil)
    return unless row.fields.any? { |value| value.to_s.bytesize > DataImports::Csv::UploadValidator::MAX_FIELD_SIZE }

    raise CustomExceptions::DataImport::InvalidCsvError, "Record #{number} contains a field larger than 1 MiB."
  end
end
