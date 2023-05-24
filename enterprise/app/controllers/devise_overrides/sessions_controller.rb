class DeviseOverrides::EnterpriseSessionsController
  def create_audit_event
    return unless @resource

    associated_type = 'Account'
    @resource.accounts.each do |account|
      @resource.audits.create(
        action: 'sign_in',
        user_id: @resource.id,
        associated_id: account.id,
        associated_type: associated_type
      )
    end
  end
end
