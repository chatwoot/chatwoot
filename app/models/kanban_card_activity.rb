# == Schema Information
#
# Table name: kanban_card_activities
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  from_column_id :bigint
#  kanban_card_id :bigint           not null
#  to_column_id   :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_kanban_card_activities_on_from_column_id                 (from_column_id)
#  index_kanban_card_activities_on_kanban_card_id                 (kanban_card_id)
#  index_kanban_card_activities_on_kanban_card_id_and_created_at  (kanban_card_id,created_at)
#  index_kanban_card_activities_on_to_column_id                   (to_column_id)
#  index_kanban_card_activities_on_user_id                        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (from_column_id => kanban_columns.id)
#  fk_rails_...  (kanban_card_id => kanban_cards.id)
#  fk_rails_...  (to_column_id => kanban_columns.id)
#  fk_rails_...  (user_id => users.id)
#
class KanbanCardActivity < ApplicationRecord
  belongs_to :kanban_card
  belongs_to :from_column, class_name: 'KanbanColumn', optional: true
  belongs_to :to_column, class_name: 'KanbanColumn'
  belongs_to :user

  default_scope { order(created_at: :desc) }
end
