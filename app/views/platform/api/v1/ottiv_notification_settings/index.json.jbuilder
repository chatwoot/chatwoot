json.accounts do
  json.array! @accounts do |account|
    json.id account.id
    json.name account.name
    json.locale account.locale
    json.status account.status

    json.users do
      json.array! account.users do |user|
        json.id user.id
        json.email user.email
        json.name user.name
        json.display_name user.display_name
        json.access_token user.access_token&.token

        # Notification Settings do usuário para esta account (apenas ottiv_*)
        ottiv_notification_setting = user.ottiv_notification_settings.detect { |ns| ns.account_id == account.id }
        if ottiv_notification_setting
          json.notification_setting do
            json.id ottiv_notification_setting.id
            json.account_id ottiv_notification_setting.account_id
            json.user_id ottiv_notification_setting.user_id
            json.all_email_flags ottiv_notification_setting.all_email_flags
            json.selected_email_flags ottiv_notification_setting.selected_email_flags
            json.all_push_flags ottiv_notification_setting.all_push_flags
            json.selected_push_flags ottiv_notification_setting.selected_push_flags
          end
        else
          json.notification_setting nil
        end

        # Notification Subscriptions do usuário (apenas ottiv_*)
        ottiv_subscriptions = user.ottiv_notification_subscriptions.to_a
        json.notification_subscriptions do
          json.array! ottiv_subscriptions do |subscription|
            json.id subscription.id
            json.subscription_type subscription.subscription_type
            json.identifier subscription.identifier
            json.subscription_attributes subscription.subscription_attributes
            json.created_at subscription.created_at
            json.updated_at subscription.updated_at
          end
        end
      end
    end
  end
end

