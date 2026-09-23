module SuperAdminImpersonation
  def destroy
    token_entry = @resource&.tokens&.dig(@token.client) || {}
    impersonator_id = token_entry['impersonated_by'] || token_entry[:impersonated_by]

    super do |user|
      record_impersonation_event('impersonation_ended', user, impersonator_id) if impersonator_id.present?
      yield user if block_given?
    end
  end

  private

  def record_impersonation_event(action, user, impersonator_id)
    SuperAdminAuditLog.create!(
      action: action,
      super_admin_id: impersonator_id,
      target_user: user,
      metadata: { account_ids: user.accounts.ids },
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end

  def make_room_for_impersonation_token
    return if @resource.tokens.size < DeviseTokenAuth.max_number_of_devices

    oldest_client_id = @resource.tokens.min_by { |_, v| v['expiry'].to_i }&.first
    @resource.tokens.delete(oldest_client_id) if oldest_client_id
  end
end
