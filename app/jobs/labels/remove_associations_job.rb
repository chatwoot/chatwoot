class Labels::RemoveAssociationsJob < ApplicationJob
  queue_as :default

  def perform(label_title:, account_id:, tagging_ids:)
    Labels::DestroyService.new(
      label_title: label_title,
      account_id: account_id,
      tagging_ids: tagging_ids
    ).perform
  end
end
