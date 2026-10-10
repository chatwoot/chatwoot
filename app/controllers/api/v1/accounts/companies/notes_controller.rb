class Api::V1::Accounts::Companies::NotesController < Api::V1::Accounts::Companies::BaseController
  RESULTS_PER_PAGE = 20

  before_action :authorize_company_read!

  def index
    notes = Current.account.notes.where(contact_id: @company.contacts.select(:id))
    notes = notes.where('notes.content ILIKE ?', "%#{Note.sanitize_sql_like(params[:q].strip)}%") if params[:q].present?
    @notes = notes.latest
                  .includes(:contact, :user)
                  .page(params[:page] || 1)
                  .per(RESULTS_PER_PAGE)
  end
end
