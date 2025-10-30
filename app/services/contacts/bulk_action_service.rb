class Contacts::BulkActionService
  def initialize(account:, user:, params:)
    @account = account
    @user = user
    @params = params.deep_symbolize_keys
  end

  def perform
    return assign_labels if labels_to_add.any?

    Rails.logger.warn("Unknown contact bulk operation payload: #{@params.keys}")
    { success: false, error: 'unknown_operation' }
  end

  private

  def assign_labels
    Contacts::BulkAssignLabelsService.new(
      account: @account,
      contact_ids: ids,
      labels: labels_to_add
    ).perform
  end

  def ids
    Array(@params[:ids]).compact
  end

  def labels_to_add
    @labels_to_add ||= Array(@params.dig(:labels, :add)).reject(&:blank?)
  end
end
