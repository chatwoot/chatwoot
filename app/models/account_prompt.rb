# == Schema Information
#
# Table name: account_prompts
#
#  id         :uuid             not null, primary key
#  prompt_key :string           not null
#  text       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint
#
# Indexes
#
#  index_account_prompts_on_account_id                 (account_id)
#  index_account_prompts_on_account_id_and_prompt_key  (account_id,prompt_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class AccountPrompt < ApplicationRecord
  belongs_to :account
  validates :prompt_key, presence: true
  validates :text, presence: true
end
