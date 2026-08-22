# frozen_string_literal: true

# Dedicated, self-contained CSV contact importer endpoint.
#
# REMOVE THIS FEATURE by deleting this controller, its route
# (`resources :csv_import`), and the app/services/csv_import directory.
class Api::V1::Accounts::CsvImportController < Api::V1::Accounts::BaseController
  before_action :check_csv_import_authorization

  # POST /api/v1/accounts/:account_id/csv_import
  # params:
  #   import_file : ActionDispatch::Http::UploadedFile (CSV)
  #   inbox_id    : optional — if present, imported contacts are linked to the inbox
  def create
    render json: { error: I18n.t('errors.contacts.import.failed') }, status: :unprocessable_entity and return if params[:import_file].blank?

    result = CsvImport::Importer.new(account: Current.account, csv_io: params[:import_file]).perform

    if params[:inbox_id].present?
      inbox = Current.account.inboxes.find(params[:inbox_id])
      link_contacts_to_inbox(inbox, result[:contact_ids])
    end

    render json: {
      success: true,
      imported: result[:created],
      updated: result[:updated],
      skipped: result[:skipped],
      companies_created: result[:companies_created],
      companies_updated: result[:companies_updated],
      total_rows: result[:rows]
    }, status: :ok
  rescue StandardError => e
    Rails.logger.error("CsvImport failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  # There is no CsvImport model for the default check_authorization lookup, so
  # authorize the feature policy directly.
  def check_csv_import_authorization
    authorize(:csv_import, :create?)
  end

  def link_contacts_to_inbox(inbox, contact_ids)
    Current.account.contacts.where(id: contact_ids).find_each do |contact|
      ContactInboxBuilder.new(contact: contact, inbox: inbox).perform
    end
  end
end
