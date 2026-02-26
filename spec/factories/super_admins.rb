# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  agent_key              :string
#  availability           :integer          default("online")
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  consumed_timestep      :integer
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  custom_attributes      :jsonb
#  display_name           :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  is_ai                  :boolean          default(FALSE), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  message_signature      :text
#  name                   :string           not null
#  otp_backup_codes       :text
#  otp_required_for_login :boolean          default(FALSE), not null
#  otp_secret             :string
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
#  clerk_user_id          :string
#  human_agent_id         :bigint
#
# Indexes
#
#  index_users_on_clerk_user_id           (clerk_user_id) UNIQUE WHERE (clerk_user_id IS NOT NULL)
#  index_users_on_email                   (email)
#  index_users_on_human_agent_id          (human_agent_id)
#  index_users_on_otp_required_for_login  (otp_required_for_login)
#  index_users_on_otp_secret              (otp_secret) UNIQUE
#  index_users_on_pubsub_token            (pubsub_token) UNIQUE
#  index_users_on_reset_password_token    (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider        (uid,provider) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (human_agent_id => users.id)
#
FactoryBot.define do
  factory :super_admin do
    name { Faker::Name.name }
    email { "admin@#{SecureRandom.uuid}.com" }
    password { 'Password1!' }
    type { 'SuperAdmin' }
    confirmed_at { Time.zone.now }
  end
end
