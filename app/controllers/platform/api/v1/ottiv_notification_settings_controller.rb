class Platform::Api::V1::OttivNotificationSettingsController < PlatformController
  skip_before_action :set_resource, only: [:index]
  skip_before_action :validate_platform_app_permissible, only: [:index]

  def index
    account_ids = @platform_app.platform_app_permissibles
                              .where(permissible_type: 'Account')
                              .pluck(:permissible_id)

    @accounts = Account.where(id: account_ids)
                    .includes(
                      account_users: {
                        user: [
                          :ottiv_notification_settings,
                          :ottiv_notification_subscriptions,
                          :access_token
                        ]
                      }
                    )
  end
end

