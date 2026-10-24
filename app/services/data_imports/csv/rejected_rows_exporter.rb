class DataImports::Csv::RejectedRowsExporter
  def initialize(data_import)
    @data_import = data_import
  end

  def perform
    return if @data_import.items.failed.none?

    headers = @data_import.source_metadata.fetch('headers').excluding('errors')
    Tempfile.create(['rejected-contacts', '.csv']) do |file|
      file.write(CSVSafe.generate_line(headers + ['errors']))
      @data_import.items.failed.find_each do |item|
        file.write(CSVSafe.generate_line(headers.map { |header| item.metadata.fetch('fields')[header] } + [item.last_error_message]))
      end
      attach_file(file)
    end
  end

  private

  def attach_file(file)
    file.rewind
    blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: "contacts-#{@data_import.id}-rejected.csv", content_type: 'text/csv')
    @data_import.failed_records.attach(blob)
  ensure
    blob&.purge_later if blob && !blob.attachments.exists?
  end
end
