class DataImports::RestartService
  attr_reader :data_import

  def initialize(account:, data_import:)
    @account = account
    @data_import = data_import
  end

  def perform
    @account.with_lock do
      @data_import.with_lock { restart_locked }
    end
  end

  private

  def restart_locked
    return :render_show unless @data_import.managed_import?
    return :render_show unless @data_import.restartable?

    if (active_import = find_active_import)
      @data_import = active_import
      return :render_show
    end

    return :access_token_missing unless @data_import.source_available?

    @data_import.assign_active_import_run_id
    reset_csv_items if @data_import.csv_import?
    retained_skip_logs = @data_import.import_errors.where("details ->> 'kind' = ?", 'skipped')
    @data_import.import_errors.where.not(id: retained_skip_logs.select(:id)).delete_all
    @data_import.update!(restart_attributes(retained_skip_logs))
    :enqueue
  end

  def find_active_import
    @account.data_imports.active_imports.first
  end

  def reset_csv_items
    @data_import.items.failed.update_all(status: :pending) # rubocop:disable Rails/SkipsModelValidations
    @data_import.cursor = @data_import.cursor.except('contacts')
  end

  def restart_attributes(retained_skip_logs)
    {
      status: :pending,
      abandoned_at: nil,
      completed_at: nil,
      last_error_at: nil,
      started_at: nil,
      stats: restart_stats(retained_skip_logs)
    }
  end

  def restart_stats(retained_skip_logs)
    @data_import.stats.to_h.deep_dup.tap do |stats|
      %w[contact conversation message].each do |object_type|
        stats["#{object_type}s"] ||= {}
        stats["#{object_type}s"]['skipped'] = retained_skip_logs.where(source_object_type: object_type).count
      end
      stats['errors'] = { 'count' => 0 }
      if @data_import.csv_import?
        stats['contacts']['failed'] = 0
        stats['contacts']['processed'] = stats['contacts'].fetch('imported', 0)
      end
    end
  end
end
