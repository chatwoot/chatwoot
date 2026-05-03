# == Schema Information
#
# Table name: kanban_columns
#
#  id              :bigint           not null, primary key
#  color           :string
#  column_function :integer          default("no_function"), not null
#  column_type     :integer          default("standard"), not null
#  name            :string           not null
#  position        :float            default(1.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#
# Indexes
#
#  index_kanban_columns_on_account_id               (account_id)
#  index_kanban_columns_on_account_id_and_position  (account_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class KanbanColumn < ApplicationRecord
  belongs_to :account

  enum :column_type, { standard: 0, won: 1, lost: 2 }
  enum :column_function, { no_function: 0, auto_receive: 1 }

  validate :unique_auto_receive_per_account, if: :auto_receive?

  def self.auto_receive_for(account)
    where(account: account, column_function: :auto_receive).first
  end

  before_destroy :ensure_no_cards

  has_many :cards, class_name: 'KanbanCard', dependent: :destroy
  has_many :from_activities, class_name: 'KanbanCardActivity', foreign_key: :from_column_id, dependent: :nullify
  has_many :to_activities, class_name: 'KanbanCardActivity', foreign_key: :to_column_id, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :account_id, case_sensitive: false,
                                 message: I18n.t('errors.kanban.column.name.taken',
                                                 default: 'already exists in this account') }
  validates :position, presence: true, numericality: true

  default_scope { order(:position) }

  def self.next_position(account_id)
    where(account_id: account_id).maximum(:position).to_f + 1.0
  end

  private

  def unique_auto_receive_per_account
    return unless account.kanban_columns.auto_receive.where.not(id: id).exists?

    errors.add(:column_function, I18n.t('errors.kanban.column.function.taken',
                                        default: 'another column already has this function'))
  end

  def ensure_no_cards
    return unless KanbanCard.exists?(kanban_column_id: id)

    errors.add(:base, I18n.t(
                        'errors.kanban.column.destroy.has_cards',
                        default: 'Cannot delete column with existing leads. Move or delete all leads first.'
                      ))
    throw :abort
  end
end
