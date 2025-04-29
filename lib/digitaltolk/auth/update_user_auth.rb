class Digitaltolk::Auth::UpdateUserAuth
  def initialize(user, data)
    @user = user
    @data = data
  end

  def perform
    return if @user.blank?
    return if @data.blank?

    normalize_data!
    save_user_auth!
  rescue StandardError => e
    Rails.logger.error "Error updating user auth: #{e.message}"
    nil
  end

  private

  def normalize_data!
    @data = @data.with_indifferent_access
  end

  def expiration
    Time.zone.now + @data['expires_in'].to_i.seconds
  end

  def save_user_auth!
    user_auth = UserAuth.find_or_initialize_by(user_id: @user.id)
    user_auth.assign_attributes(
      tenant_id: user_auth&.tenant_id || ENV.fetch('DT_TENANT_UUID', nil),
      access_token: @data['access_token'],
      refresh_token: @data['refresh_token'],
      client_id: user_auth&.client_id || ENV.fetch('DT_CLIENT_ID', nil),
      client_secret: user_auth&.client_secret || ENV.fetch('DT_CLIENT_SECRET', nil),
      expiration_datetime: expiration
    )
    user_auth.save!
    user_auth
  end
end
