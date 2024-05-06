class Account::ContactsExportJob < ApplicationJob
  queue_as :low

  def perform(account_id, column_names, params, user_id)
    @account = Account.find(account_id)
    @params = params
    @current_user = User.find(user_id)

    headers = valid_headers(column_names)
    generate_csv(headers)
    send_mail
  end

  private

  def generate_csv(headers)
    csv_data = CSV.generate do |csv|
      csv << headers
      contacts.each do |contact|
        csv << headers.map { |header| contact.send(header) }
      end
    end

    attach_export_file(csv_data)
  end

  def contacts
    return @account.contacts.tagged_with(@params[:label], any: true) if @params[:label].present?

    result = ::Contacts::FilterService.new(@params, @current_user, @account).perform
    result[:contacts]
  end

  def valid_headers(column_names)
    (column_names.presence || default_columns) & Contact.column_names
  end

  def attach_export_file(csv_data)
    return if csv_data.blank?

    @account.contacts_export.attach(
      io: StringIO.new(csv_data),
      filename: "#{@account.name}_#{@account.id}_contacts.csv",
      content_type: 'text/csv'
    )
  end

  def send_mail
    file_url = account_contact_export_url
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: @account)
    mailer.contact_export_complete(file_url, @current_user.email)&.deliver_later
  end

  def account_contact_export_url
    Rails.application.routes.url_helpers.rails_blob_url(@account.contacts_export)
  end

  def default_columns
    %w[id name email phone_number]
  end
end
