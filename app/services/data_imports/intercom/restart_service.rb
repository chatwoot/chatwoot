class DataImports::Intercom::RestartService
  attr_reader :data_import

  def initialize(account:, data_import:)
    @account = account
    @data_import = data_import
  end

  def perform
    @account.with_lock do
      @data_import.reload
      next :render_show unless @data_import.restartable?

      if (active_import = find_active_import)
        @data_import = active_import
        next :render_show
      end

      next :access_token_missing if @data_import.access_token.blank?

      @data_import.assign_active_intercom_import_run_id
      retained_skip_logs = @data_import.import_errors.where("details ->> 'kind' = ?", 'skipped')
      @data_import.import_errors.where.not(id: retained_skip_logs.select(:id)).delete_all
      @data_import.update!(restart_attributes(retained_skip_logs))
      :enqueue
    end
  end

  private

  def find_active_import
    @account.data_imports.active_intercom.first
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
    end
  end
end
