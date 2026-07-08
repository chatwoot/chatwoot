# frozen_string_literal: true

module Enterprise::Api::V1::Accounts::Whatsapp::AuthorizationsController
  def create
    ensure_inbox_create_permitted if params[:inbox_id].blank?
    super
  end

  private

  def ensure_inbox_create_permitted
    Current.account.inboxes.build.ensure_create_permitted
  end
end
