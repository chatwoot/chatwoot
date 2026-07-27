class DataImports::Intercom::RetryService
  attr_reader :data_import

  def initialize(account:, data_import:)
    @account = account
    @data_import = data_import
  end

  def perform
    @account.with_lock do
      @data_import.with_lock do
        next :not_stalled unless @data_import.stalled?
        next :active_import_exists if another_active_import?
        next :access_token_missing if @data_import.access_token.blank?

        @data_import.assign_active_intercom_import_run_id
        @data_import.update!(status: :pending)
        :enqueue
      end
    end
  end

  private

  def another_active_import?
    @account.data_imports.active_intercom.where.not(id: @data_import.id).exists?
  end
end
