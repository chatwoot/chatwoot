# == Schema Information
#
# Table name: agent_bots
#
#  id           :bigint           not null, primary key
#  bot_config   :jsonb
#  bot_type     :integer          default("webhook")
#  description  :string
#  name         :string
#  outgoing_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint
#
# Indexes
#
#  index_agent_bots_on_account_id  (account_id)
#
FactoryBot.define do
  factory :agent_bot do
    name { 'MyString' }
    description { 'MyString' }
    outgoing_url { 'localhost' }
    bot_config { {} }
    bot_type { 'webhook' }

    trait :skip_validate do
      to_create { |instance| instance.save(validate: false) }
    end

    trait :with_avatar do
      avatar { fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }
    end
  end
end
