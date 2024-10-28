class Migration::SetupTicketLabelsJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    create_contact_type_labels
    create_additional_labels
  end

  private

  def create_additional_labels
    labels = %w[created-by-agent feedback question 2nd-line-support]

    [1, 3].each do |account_id|
      account = Account.find_by(id: account_id)
      next if account.blank?

      labels.each do |title|
        label = account.labels.find_or_create_by({ title: title })
        label.update({
                       description: title,
                       color: Faker::Color.hex_color,
                       show_on_sidebar: true
                     })
      end
    end
  end

  def create_contact_type_labels
    [1, 3].each do |account_id|
      account = Account.find_by(id: account_id)
      next if account.blank?

      Digitaltolk::ChangeContactKindService::KIND_LABELS.each do |_key, value|
        label = account.labels.find_or_create_by({ title: value })

        label.update({
                       description: value,
                       color: Faker::Color.hex_color,
                       show_on_sidebar: true
                     })
      end
    end
  end
end
