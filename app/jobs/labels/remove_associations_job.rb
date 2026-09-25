class Labels::RemoveAssociationsJob < ApplicationJob
  queue_as :within_1_minute

  def perform(label_title:, account_id:, label_deleted_at:)
    Labels::DestroyService.new(
      label_title: label_title,
      account_id: account_id,
      label_deleted_at: label_deleted_at
    ).perform
  end
end
