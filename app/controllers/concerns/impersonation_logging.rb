module ImpersonationLogging
  def destroy
    token_entry = impersonation_token_entry
    return super unless token_entry

    super do |user|
      ImpersonationLogger.log('ended', user: user, super_admin_id: token_entry[:impersonated_by], ip: request.remote_ip)
      yield user if block_given?
    end
  end

  private

  def impersonation_token_entry
    token_entry = (@resource&.tokens&.dig(@token&.client) || {}).with_indifferent_access
    token_entry if token_entry[:impersonation]
  end

  def log_impersonation_started
    ImpersonationLogger.log('started', user: @resource, super_admin_id: @impersonator_id, ip: request.remote_ip)
  end
end
