module LoginLocationNotification
  def self.enabled?
    ActiveModel::Type::Boolean.new.cast(GlobalConfig.get_value('LOGIN_LOCATION_NOTIFICATION_ENABLED')).present?
  end
end
