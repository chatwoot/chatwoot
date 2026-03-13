# == Schema Information
#
# Table name: conversation_classifications
#
#  id         :bigint           not null, primary key
#  account_id :bigint           not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_conversation_classifications_on_account_id           (account_id)
#  index_conversation_classifications_on_account_id_and_name  (account_id, name) UNIQUE
#

class ConversationClassification < ApplicationRecord
  belongs_to :account
  has_many :conversations, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :name, length: { maximum: 100 }

  default_scope { order(:position, :name) }
end
