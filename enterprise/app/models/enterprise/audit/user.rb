module Enterprise::Audit::User
  extend ActiveSupport::Concern

  included do
    audited except: [
      :confirmation_sent_at,
      :confirmation_token,
      :confirmed_at,
      :current_sign_in_at,
      :current_sign_in_ip,
      :encrypted_password,
      :last_sign_in_at,
      :last_sign_in_ip,
      :message_signature,
      :provider,
      :pubsub_token,
      :remember_created_at,
      :reset_password_sent_at,
      :reset_password_token,
      :sign_in_count,
      :tokens,
      :type,
      :ui_settings,
      :uid,
      :unconfirmed_email
    ]

    audited associated_with: :account
  end
end
