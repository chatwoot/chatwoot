class Account::PaymentLinksExportJob < ApplicationJob
  queue_as :low

  def perform(account_id, user_id)
    @account = Account.find(account_id)
    @account_user = @account.users.find(user_id)

    generate_csv
    send_mail
  end

  private

  def generate_csv
    csv_data = CSV.generate do |csv|
      csv << headers
      payment_links.each do |payment_link|
        csv << row_data(payment_link)
      end
    end

    attach_export_file(csv_data)
  end

  def headers
    [
      'Payment ID',
      'Contact Name',
      'Contact Email',
      'Contact Phone',
      'Amount',
      'Currency',
      'Status',
      'Created By',
      'Conversation ID',
      'Created At',
      'Paid At',
      'Payment URL'
    ]
  end

  def row_data(payment_link)
    [
      payment_link.external_payment_id,
      payment_link.contact&.name,
      payment_link.contact&.email,
      payment_link.contact&.phone_number,
      payment_link.amount,
      payment_link.currency,
      payment_link.status,
      payment_link.created_by&.name,
      payment_link.conversation&.display_id,
      format_date(payment_link.created_at),
      format_date(payment_link.paid_at),
      payment_link.payment_url
    ]
  end

  def payment_links
    @account.payment_links.includes(:contact, :created_by, :conversation).order(created_at: :desc)
  end

  def format_date(date)
    return nil if date.blank?

    date.strftime('%Y-%m-%d %H:%M:%S')
  end

  def attach_export_file(csv_data)
    return if csv_data.blank?

    @account.payment_links_export.attach(
      io: StringIO.new(csv_data),
      filename: "#{@account.name}_#{@account.id}_payment_links.csv",
      content_type: 'text/csv'
    )
  end

  def send_mail
    file_url = account_payment_links_export_url
    mailer = AdministratorNotifications::AccountNotificationMailer.with(account: @account)
    mailer.payment_links_export_complete(file_url, @account_user.email)&.deliver_later
  end

  def account_payment_links_export_url
    Rails.application.routes.url_helpers.rails_blob_url(@account.payment_links_export)
  end
end
