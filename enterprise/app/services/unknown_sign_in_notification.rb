module UnknownSignInNotification
  def self.enabled?
    ActiveModel::Type::Boolean.new.cast(GlobalConfig.get_value('UNKNOWN_SIGNIN_NOTIFICATION_ENABLED')).present?
  end
end
