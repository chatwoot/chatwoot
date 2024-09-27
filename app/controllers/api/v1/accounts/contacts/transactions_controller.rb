class Api::V1::Accounts::Contacts::TransactionsController < Api::V1::Accounts::Contacts::BaseController
  def index
    @transactions = Current.account.contact_transactions.includes(:product)
                           .where(contact_id: @contact.id).order(id: :desc).limit(10)
  end
end
