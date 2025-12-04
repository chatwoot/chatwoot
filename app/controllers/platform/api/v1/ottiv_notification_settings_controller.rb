class Platform::Api::V1::OttivNotificationSettingsController < PlatformController
  skip_before_action :set_resource, only: [:index]
  skip_before_action :validate_platform_app_permissible, only: [:index]

  def index
    # ✅ Retornar todos os accounts que têm usuários
    # Isso garante que todos os accounts sejam incluídos,
    # independente de estarem explicitamente permitidos no platform_app_permissibles
    # ou terem subscriptions/settings já criadas
    @accounts = Account.joins(:account_users)
                    .distinct
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

