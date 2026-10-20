class UserSessionTrackingService
  CLIENT_METADATA_COLUMNS = %i[browser_name browser_version device_name platform_name platform_version].freeze
  private_constant :CLIENT_METADATA_COLUMNS

  def initialize(user:, request:, client_id:)
    @user = user
    @request = request
    @client_id = client_id
  end

  def create_or_update!
    session = @user.user_sessions.find_or_initialize_by(client_id: @client_id)
    session.assign_attributes(session_attributes)
    session.last_activity_at = Time.current
    session.save!
    UserSessionIpLookupJob.perform_later(session) if session.ip_address.present?
    session
  end

  def update_activity!
    session = @user.user_sessions.find_by(client_id: @client_id)
    return unless session&.should_update_activity?

    attributes = { last_activity_at: Time.current }.merge(changed_client_metadata(session))
    session.update_columns(attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  # Tokens do not rotate and last two months, so a client that upgrades without signing in
  # again keeps the version it reported at sign-in unless these are refreshed.
  def changed_client_metadata(session)
    current = RequestDeviceInfo.new(@request).to_h.slice(*CLIENT_METADATA_COLUMNS)
    current.reject { |column, value| session.public_send(column) == value }
  end

  def session_attributes
    RequestDeviceInfo.new(@request).to_h.merge(
      ip_address: @request.remote_ip,
      user_agent: @request.user_agent
    )
  end
end
