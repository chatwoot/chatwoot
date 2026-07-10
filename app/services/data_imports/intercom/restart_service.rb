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
      DataImportError.where(data_import_id: @data_import.id).delete_all
      @data_import.update!(status: :pending, abandoned_at: nil, completed_at: nil, last_error_at: nil, started_at: nil)
      :enqueue
    end
  end

  private

  def find_active_import
    @account.data_imports.active_intercom.first
  end
end
