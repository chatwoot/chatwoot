module Enteprise::Channelable
  extend ActiveSupport::Concern

  def create_audit_log_entry?
    @resource.audits.create(
      action: 'update',
      user_id: Current.user.id,
      associated_id: @resource.account.id,
      associated_type: @resource.class.name
    )
  end
end
