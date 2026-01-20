# == Schema Information
#
# Table name: priority_groups
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_priority_groups_on_account_id           (account_id)
#  index_priority_groups_on_account_id_and_name  (account_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class PriorityGroup < ApplicationRecord
  has_many :inboxes, dependent: :destroy
  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id }
end
