class DataImports::Intercom::ConnectionService
  def initialize(account:, access_token:)
    @account = account
    @access_token = access_token.to_s.strip
  end

  def perform
    raise ArgumentError, 'Access token is required' if @access_token.blank?
    raise ArgumentError, 'Intercom cannot be connected while an import is active.' if active_intercom_import?

    client.validate!
    upsert_hook
  end

  private

  def client
    @client ||= DataImports::Intercom::Client.new(access_token: @access_token)
  end

  def active_intercom_import?
    @account.data_imports.exists?(source_provider: 'intercom', status: [:pending, :processing])
  end

  def upsert_hook
    hook = @account.hooks.find_or_initialize_by(app_id: 'intercom')
    hook.access_token = @access_token
    hook.status = 'enabled'
    hook.settings = hook.settings.to_h.merge(
      'workspace_name' => hook.settings&.dig('workspace_name').presence || 'Intercom workspace',
      'last_validated_at' => Time.current.iso8601
    )
    hook.save!
    hook
  end
end
