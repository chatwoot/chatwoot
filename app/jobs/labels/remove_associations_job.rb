class Labels::RemoveAssociationsJob < ApplicationJob
  queue_as :default

  def perform(label_title:, account_id:)
    Labels::DestroyService.new(
      label_title: label_title,
      account_id: account_id
    ).perform
  end
end
