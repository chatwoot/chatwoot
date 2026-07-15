# == Schema Information
#
# Table name: kanban_boards
#
#  id          :bigint           not null, primary key
#  board_type  :integer          default("conversation"), not null
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_kanban_boards_on_account_id           (account_id)
#  index_kanban_boards_on_account_id_and_name  (account_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class KanbanBoard < ApplicationRecord
  belongs_to :account
  has_many :kanban_cards, dependent: :delete_all
  has_many :kanban_columns, dependent: :destroy

  enum board_type: { conversation: 0 }

  validates :name, presence: true, uniqueness: { scope: :account_id }
end
