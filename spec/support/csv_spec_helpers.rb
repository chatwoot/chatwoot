module CsvSpecHelpers
  # Generates a Rack::Test::UploadedFile object from an array of arrays
  # data: Accepts an array of arrays as the only argument
  def generate_csv_file(data)
    # Create a temporary file
    temp_file = Tempfile.new(['data', '.csv'])

    # Write the array of arrays to the temporary file as CSV
    CSV.open(temp_file.path, 'wb') do |csv|
      data.each do |row|
        csv << row
      end
    end

    # Create and return a Rack::Test::UploadedFile object
    Rack::Test::UploadedFile.new(temp_file.path, 'text/csv')
  end
end
