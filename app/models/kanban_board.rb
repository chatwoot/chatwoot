# == Schema Information
#
# Table name: kanban_boards
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_kanban_boards_on_account_id              (account_id)
#  index_kanban_boards_on_account_id_and_user_id  (account_id,user_id) UNIQUE
#  index_kanban_boards_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class KanbanBoard < ApplicationRecord
  belongs_to :account
  belongs_to :user

  has_many :cards, class_name: 'KanbanCard', dependent: :destroy

  validates :account_id, uniqueness: { scope: :user_id }

  after_create :ensure_account_columns

  private

  def ensure_account_columns
    return if account.kanban_columns.any?

    [
      { name: I18n.t('kanban.default_columns.waiting', default: 'Aguardando atendimento'), position: 1.0, column_type: :standard },
      { name: I18n.t('kanban.default_columns.won', default: 'Venda ganha'), position: 2.0, column_type: :won },
      { name: I18n.t('kanban.default_columns.lost', default: 'Venda perdida'), position: 3.0, column_type: :lost }
    ].each do |attrs|
      account.kanban_columns.create!(attrs)
    end
  end
end
