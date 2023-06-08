class Account::ContactsExportJob < ApplicationJob
  queue_as :low

  def perform(account_id, column_names)
    headers = valid_headers(column_names)
    account = Account.find(account_id)

    file_url = generate_csv(account, headers)

    TeamNotifications::ContactNotificationMailer.contact_export_notification(account, file_url)&.deliver_now
  end

  def generate_csv(account, headers)
    file_blob_url = nil

    Tempfile.open(["#{account.name}_#{account.id}_contacts", '.csv']).tap do |tempfile|
      CSV.open(tempfile, 'w', write_headers: true, headers: headers) do |writer|
        account.contacts.each do |contact|
          writer << headers.map { |header| contact.send(header) }
        end
      end
      file_blob_url = attach_export_file(account, tempfile)
    end
    file_blob_url
  end

  def valid_headers(column_names)
    columns = (column_names.presence || default_columns)
    headers = columns.map { |column| column if Contact.column_names.include?(column) }
    headers.compact
  end

  def attach_export_file(account, tempfile)
    file_blob = ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: tempfile,
      filename: "#{account.name}_#{account.id}_contacts",
      content_type: 'text/csv'
    )
    file_blob.save!

    Rails.application.routes.url_helpers.url_for(file_blob)
  end

  def default_columns
    %w[id name email phone_number]
  end
end
