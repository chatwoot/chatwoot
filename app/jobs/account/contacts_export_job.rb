class Account::ContactsExportJob < ApplicationJob
  queue_as :low

  def perform(account_id, column_names)
    headers = valid_headers(column_names)
    account = Account.find(account_id)

    file = "#{Rails.root}/public/#{account.name}_#{account.id}_contacts.csv"

    CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
      account.contacts.each do |contact|
        writer << headers.map { |header| contact.send(header) }
      end
    end

    TeamNotifications::ContactNotificationMailer.contact_export_notification(account)&.deliver_now
  end

  def valid_headers(column_names)
    columns = column_names || default_columns
    headers = columns.map { |column| column if Contact.column_names.include?(column) }
    headers.compact
  end

  def default_columns
    %w[id name email phone_number]
  end
end
