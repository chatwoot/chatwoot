module Enterprise::AccountUser
  def permissions
    custom_role.present? ? (custom_role.permissions + ['custom_role']) : super
  end

  # Missed calls are pushed by default, alongside the core defaults
  def create_notification_setting
    super
    setting = user.notification_settings.find_by(account_id: account_id)
    setting.push_voice_call_missed = true
    setting.save!
  end
end
