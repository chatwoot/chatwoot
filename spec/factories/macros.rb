# == Schema Information
#
# Table name: macros
#
#  id            :bigint           not null, primary key
#  actions       :jsonb            not null
#  ai_enabled    :boolean          default(FALSE), not null
#  description   :text
#  name          :string           not null
#  visibility    :integer          default("personal")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  created_by_id :bigint
#  updated_by_id :bigint
#
# Indexes
#
#  index_macros_on_account_id             (account_id)
#  index_macros_on_account_id_ai_enabled  (account_id,ai_enabled) WHERE (ai_enabled = true)
#
FactoryBot.define do
  factory :macro do
    account
    name { 'wrong_message_actions' }
    actions do
      [
        { 'action_name' => 'add_label', 'action_params' => %w[wrong_chat] }
      ]
    end
  end
end
