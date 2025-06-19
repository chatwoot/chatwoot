# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  availability           :integer          default("online")
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  custom_attributes      :jsonb
#  display_name           :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  message_signature      :text
#  name                   :string           not null
#  provider               :string           default("email"), not null
#  pubsub_token           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  tokens                 :json
#  type                   :string
#  ui_settings            :jsonb
#  uid                    :string           default(""), not null
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email)
#  index_users_on_pubsub_token          (pubsub_token) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#

class SuperAdmin < User
  # Super Admin com acesso total Enterprise

  def enterprise_enabled?
    true
  end

  def feature_enabled?(_feature)
    true  # Super Admin tem acesso a todas as features
  end

  def can_access_enterprise_features?
    true
  end

  def has_enterprise_access?
    true
  end

  def enterprise_features_enabled?
    true
  end

  # Sobrescrever verificações de limite
  def usage_limits
    {
      agents: Float::INFINITY,
      inboxes: Float::INFINITY,
      campaigns: Float::INFINITY,
      automations: Float::INFINITY
    }
  end

  # Acesso a todas as contas
  def accessible_accounts
    Account.all
  end

  # CORRIGIDO: Super Admin deve retornar um AccountUser válido
  def active_account_user
    # Retornar a primeira associação de conta ou criar uma temporária
    account_users.first || AccountUser.new(
      account: Account.first || Account.create!(name: 'Super Admin Account'),
      user: self,
      role: 'administrator'
    )
  end
end
