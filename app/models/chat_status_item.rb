# == Schema Information
#
# Table name: chat_status_items
#
#  id         :bigint           not null, primary key
#  custom     :boolean          default(TRUE)
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_chat_status_items_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class ChatStatusItem < ApplicationRecord
  belongs_to :account
end
