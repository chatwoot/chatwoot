# Restore the Companies feature (dropped with enterprise edition).
# Nested contacts endpoint: list/detach contacts belonging to a company, and
# search for contacts to attach.
class Api::V1::Accounts::Companies::ContactsController < Api::V1::Accounts::BaseController
  before_action :company
  before_action :check_authorization

  RESULTS_PER_PAGE = 15

  def index
    @contacts = company.contacts.page(params[:page] || 1).per(RESULTS_PER_PAGE)
    @contacts_count = company.contacts.count
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity and return if params[:q].blank?

    # Contacts not already attached to this company.
    contacts = Current.account.contacts.where.not(id: company.contact_ids)
                .where('name ILIKE :s OR email ILIKE :s OR phone_number ILIKE :s', s: "%#{params[:q].strip}%")
    @contacts = contacts.page(params[:page] || 1).per(RESULTS_PER_PAGE)
    render 'index'
  end

  def create
    contact = Current.account.contacts.find(params[:contact_id])
    contact.update!(company_id: company.id)
    @contact = contact
    render 'show'
  end

  def destroy
    contact = company.contacts.find(params[:id])
    contact.update!(company_id: nil)
    head :ok
  end

  private

  def company
    @company ||= Current.account.companies.find(params[:company_id])
  end
end
