class DataImports::Csv::RejectedRowsExporter
  def initialize(data_import)
    @data_import = data_import
  end

  def perform
    return if @data_import.items.failed.none?

    headers = @data_import.source_metadata.fetch('headers').excluding('errors')
    Tempfile.create(['rejected-contacts', '.csv']) do |file|
      file.write(DataImports::Csv::RejectedRowsFormat.generate_headers(headers + ['errors']))
      @data_import.items.failed.find_each do |item|
        values = headers.map { |header| item.metadata.fetch('fields')[header] } + [item.last_error_message]
        file.write(DataImports::Csv::RejectedRowsFormat.generate_line(values))
      end
      upload_file(file)
    end
  end

  private

  def upload_file(file)
    file.rewind
    ActiveStorage::Blob.create_and_upload!(io: file, filename: "contacts-#{@data_import.id}-rejected.csv", content_type: 'text/csv')
  end
end
