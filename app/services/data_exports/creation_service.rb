class DataExports::CreationService
  def initialize(account:, initiated_by:, options:)
    @account = account
    @initiated_by = initiated_by
    @selection = DataExports::ContactSelection.new(account: account, user: initiated_by, options: options)
  end

  def perform
    @selection.validate!
    data_export = @account.data_exports.create!(initiated_by: @initiated_by, name: "Contacts - #{Date.current.iso8601}",
                                                export_options: @selection.options.merge(column_names: @selection.columns.uniq),
                                                active_run_id: SecureRandom.uuid)
    DataExports::ContactsJob.perform_later(data_export, data_export.active_run_id)
    data_export
  end
end
