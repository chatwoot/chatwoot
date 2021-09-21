class Labels::UpdateJob < ApplicationJob
  queue_as :default

  def perform(new_label_title, old_label_title, account_id)
    Labels::UpdateService.new(
      new_label_title: new_label_title,
      old_label_title: old_label_title,
      account_id: account_id
    ).perform
  end
end
