# Restore the Companies feature (dropped with enterprise edition).
class Api::V1::Accounts::Companies::NotesController < Api::V1::Accounts::BaseController
  before_action :company
  before_action :authorize_company_read!

  def index
    # Notes belong to contacts, so a company's notes are the notes on its
    # contacts.
    @notes = Current.account.notes
                    .where(contact_id: company.contacts.select(:id))
                    .order(created_at: :desc)
  end

  private

  def company
    @company ||= Current.account.companies.find(params[:company_id])
  end

  def authorize_company_read!
    authorize(@company, :show?)
  end
end
