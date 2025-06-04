class Account::ContactsExportJob < ApplicationJob
  queue_as :low

  def perform(account_id, user_id, column_names, params)
    @account = Account.find(account_id)
    @params = params
    @account_user = @account.users.find(user_id)

    headers = valid_headers(column_names)
    if @params.present? && @params[:payload].present? && @params[:payload].first[:campaign_id].present?
      generate_report_csv
    else
      generate_csv(headers)
    end
    send_mail
  end

  private

  def generate_report_csv
    Rails.logger.info("Generating reports csv")
    campaign_id = @params[:payload].first[:campaign_id]
    
    csv_data = CSV.generate do |csv|
      # Define the headers
      headers = %w[id name phone_number status processed_at error_message]
      csv << headers

      # Fetch all campaign_contacts for the campaign_id, joined with contacts
      campaign_contacts = @account.contacts
        .joins(:campaign_contacts)
        .where(campaign_contacts: { campaign_id: campaign_id })
        .select('contacts.id AS contact_id, contacts.name AS contact_name, contacts.phone_number AS contact_phone_number, campaign_contacts.status, campaign_contacts.processed_at, campaign_contacts.error_message')
        .order(Arel.sql("CASE campaign_contacts.status
          WHEN 'processed' THEN 1
          WHEN 'delivered' THEN 2
          WHEN 'read' THEN 3
          WHEN 'replied' THEN 4
          WHEN 'pending' THEN 5
          WHEN 'failed' THEN 6
          ELSE 7
        END"))

      # Populate the CSV rows
      campaign_contacts.each do |cc|
        row = [
          cc.contact_id,          # Contact's ID
          cc.contact_name,        # Contact's name
          cc.contact_phone_number, # Contact's phone number
          cc.status,              # Campaign contact status
          cc.processed_at,        # Processed timestamp (nil if not applicable)
          cc.error_message        # Error message (nil if not applicable)
        ]
        csv << row
      end
    end
    attach_export_file(csv_data)
  end


  def generate_csv(headers)
    Rails.logger.info("Generating contacts csv")
    csv_data = CSV.generate do |csv|
      csv << headers
      contacts.each do |contact|
        csv << headers.map { |header| contact.send(header) }
      end
    end

    attach_export_file(csv_data)
  end 

  def contacts
    if @params.present? && @params[:payload].present? && @params[:payload].first[:campaign_id].present?
      
      campaign_id = @params[:payload].first[:campaign_id]

      CUSTOM_LOGGER.info("export_job: #{status} #{campaign_id}")
      contacts = @account.contacts
             .joins(:campaign_contacts)
             .where(campaign_contacts: { campaign_id: campaign_id })
             .distinct
      CUSTOM_LOGGER.info("Contacts: #{contacts.inspect}")
      contacts
    elsif @params.present? && @params[:payload].present? && @params[:payload].any?
      result = ::Contacts::FilterService.new(@account, @account_user, @params).perform
      result[:contacts]
    elsif @params[:label].present?
      @account.contacts.resolved_contacts.tagged_with(@params[:label], any: true)
    else
      @account.contacts.resolved_contacts
    end
  end

  def valid_headers(column_names)
    Rails.logger.info("Column names: #{column_names}")
    Rails.logger.info("Default headers: #{default_columns}")
    Rails.logger.info("Contact columns #{Contact.column_names}")
    (column_names.presence || default_columns) & Contact.column_names
  end

  def attach_export_file(csv_data)
    Rails.logger.info("CSV data blank?: #{csv_data.blank?}")
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
    if @params.present? && @params[:payload].present? && @params[:payload].first[:campaign_id].present?
      mailer.contact_report_export(file_url, @account_user.email)&.deliver_later
    else  
      mailer.contact_export_complete(file_url, @account_user.email)&.deliver_later
    end
    
  end

  def account_contact_export_url
    Rails.application.routes.url_helpers.rails_blob_url(@account.contacts_export)
  end

  def default_columns
    %w[id name email phone_number]
  end
end
