class Api::V1::Accounts::Companies::NotesController < Api::V1::Accounts::Companies::BaseController
  before_action :authorize_company_read!

  def index
    @notes = Current.account.notes
                    .where(contact_id: @company.contacts.select(:id))
                    .latest
                    .includes(:contact, :user)
                    .limit(20)
  end
end
