# == Schema Information
#
# Table name: conversation_statuses
#
#  id         :bigint           not null, primary key
#  code       :integer
#  custom     :boolean          default(FALSE)
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_conversation_statuses_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class ConversationStatus < ApplicationRecord
  belongs_to :account

  before_validation do
    self.name = name.downcase if attribute_present?('name')
  end
end
