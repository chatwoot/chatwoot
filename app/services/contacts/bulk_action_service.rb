class Contacts::BulkActionService
  def initialize(account:, user:, params:)
    @account = account
    @user = user
    @params = params.deep_symbolize_keys
  end

  def perform
    case @params[:action]
    when 'assign_labels'
      Contacts::BulkAssignLabelsService.new(
        account: @account,
        contact_ids: @params[:contact_ids],
        labels: @params[:labels]
      ).perform
    else
      Rails.logger.warn("Unknown contact bulk action: #{@params[:action]}")
      { success: false, error: 'unknown_action' }
    end
  end
end
