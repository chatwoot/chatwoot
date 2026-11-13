class DataImports::Csv::PreparationJob < DataImports::BaseJob
  BATCH_SIZE = 1000

  def perform(data_import, run_id)
    return if skip_import?(data_import, run_id)

    @data_import = data_import
    @run_state = DataImports::RunState.new(data_import, run_id)
    return unless @run_state.start!

    prepare_file unless data_import.cursor.dig('preparation', 'completed')
    return if skip_import?(data_import, run_id)

    DataImports::Csv::ImportJob.perform_later(data_import, run_id)
  rescue StandardError => e
    importer_for(data_import, run_id).fail!(e)
    raise unless expected_error?(e)
  end

  private

  def expected_error?(error)
    error.is_a?(CSV::MalformedCSVError) || error.is_a?(CustomExceptions::DataImport::InvalidCsvError)
  end

  def prepare_file
    reader = DataImports::Csv::Reader.new(@data_import.import_file)
    total = 0
    reader.each.each_slice(BATCH_SIZE) do |batch|
      break unless stage(batch)

      total = batch.last.last
    end
    @run_state.with_lock do
      @data_import.update!(
        total_records: total,
        source_metadata: @data_import.source_metadata.merge('headers' => reader.headers),
        cursor: @data_import.cursor.merge('preparation' => { 'completed' => true }),
        stats: @data_import.stats.deep_merge('contacts' => { 'total' => total })
      )
    end
  end

  def stage(batch)
    rows = batch.map do |fields, number|
      { data_import_id: @data_import.id, source_provider: 'csv', source_object_type: 'contact', source_object_id: "row:#{number}",
        metadata: { fields: fields, row_number: number }, status: DataImportItem.statuses[:pending] }
    end
    @run_state.with_lock do
      # The original file is immutable. Replaying preparation only inserts missing rows.
      # rubocop:disable Rails/SkipsModelValidations
      @data_import.items.insert_all(rows, unique_by: :idx_data_import_items_on_import_and_source)
      # rubocop:enable Rails/SkipsModelValidations
      @data_import.update!(updated_at: Time.current)
    end
  end
end
