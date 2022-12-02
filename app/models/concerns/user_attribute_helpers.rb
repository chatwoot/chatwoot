module UserAttributeHelpers
  extend ActiveSupport::Concern

  def available_name
    self[:display_name].presence || name
  end

  def availability_status
    current_account_user&.availability_status
  end

  def auto_offline
    current_account_user&.auto_offline
  end

  def inviter
    current_account_user&.inviter
  end

  def active_account_user
    account_users.order(active_at: :desc)&.first
  end

  def current_account_user
    # We want to avoid subsequent queries in case where the association is preloaded.
    # using where here will trigger n+1 queries.
    account_users.find { |ac_usr| ac_usr.account_id == Current.account.id } if Current.account
  end

  def account
    current_account_user&.account
  end

  def administrator?
    current_account_user&.administrator?
  end

  def agent?
    current_account_user&.agent?
  end

  def role
    current_account_user&.role
  end

  # Used internally for Chatwoot in Chatwoot
  def hmac_identifier
    hmac_key = GlobalConfig.get('CHATWOOT_INBOX_HMAC_KEY')['CHATWOOT_INBOX_HMAC_KEY']
    return OpenSSL::HMAC.hexdigest('sha256', hmac_key, email) if hmac_key.present?

    ''
  end
end
