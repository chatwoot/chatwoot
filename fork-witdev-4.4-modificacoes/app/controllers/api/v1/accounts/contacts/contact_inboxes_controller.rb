class Api::V1::Accounts::Contacts::ContactInboxesController < Api::V1::Accounts::Contacts::BaseController
  include HmacConcern
  before_action :ensure_inbox, only: [:create]

  def create
    @contact_inbox = ContactInboxBuilder.new(
      contact: @contact,
      inbox: @inbox,
      source_id: params[:source_id],
      hmac_verified: hmac_verified?
    ).perform
  end

  private

  def ensure_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :show?
  end
end
