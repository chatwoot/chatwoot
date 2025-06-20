# == Schema Information
#
# Table name: account_prompts
#
#  id                                                                            :bigint           not null, primary key
#  prompt_key(Name/identifier of the prompt)                                     :string           not null
#  text(The actual text content of the prompt)                                   :text             not null
#  created_at                                                                    :datetime         not null
#  updated_at                                                                    :datetime         not null
#  account_id(Account ID that has access to this prompt. References accounts.id) :bigint
#
# Indexes
#
#  index_account_prompts_on_account_id                 (account_id)
#  index_account_prompts_on_account_id_and_prompt_key  (account_id,prompt_key) UNIQUE
#  index_account_prompts_on_prompt_key                 (prompt_key)
#
# Foreign Keys
#
#  account_prompts_account_id_fkey  (account_id => accounts.id)
#
class AccountPrompt < ApplicationRecord
  belongs_to :account
  validates :prompt_key, presence: true
  validates :text, presence: true
end
