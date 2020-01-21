# == Schema Information
#
# Table name: account_users
#
#  id         :bigint           not null, primary key
#  role       :integer          default("agent")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint
#  inviter_id :bigint
#  user_id    :bigint
#
# Indexes
#
#  index_account_users_on_account_id  (account_id)
#  index_account_users_on_user_id     (user_id)
#  uniq_user_id_per_account_id        (account_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#

class AccountUser < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :inviter, class_name: 'User', optional: true

  enum role: { agent: 0, administrator: 1 }
  accepts_nested_attributes_for :account

  validates :user_id, uniqueness: { scope: :account_id }
end
