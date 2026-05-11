# == Schema Information
#
# Table name: kanban_card_activities
#
#  id             :bigint           not null, primary key
#  event_type     :integer          default("stage_changed"), not null
#  metadata       :jsonb            not null
#  source         :integer          default("manual"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  from_column_id :bigint
#  kanban_card_id :bigint           not null
#  to_column_id   :bigint
#  user_id        :bigint
#
# Indexes
#
#  index_kanban_card_activities_on_event_type                     (event_type)
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
  belongs_to :to_column, class_name: 'KanbanColumn', optional: true
  belongs_to :user, optional: true

  enum :source, { manual: 0, macro: 1, system: 2 }
  enum :event_type, { stage_changed: 0, conversation_closed: 1, closure_cancelled: 2, macro_triggered: 3 }

  validate :validate_metadata_schema

  default_scope { order(created_at: :desc) }

  private

  # Validates that `metadata` carries the required keys for the
  # (event_type, source) pair documented in docs/kanban-feature/01-foundation.md.
  # Lightweight presence check — not full type validation.
  def validate_metadata_schema
    required_keys = required_metadata_keys
    return if required_keys.empty?

    missing = required_keys - metadata.keys.map(&:to_s)
    return if missing.empty?

    errors.add(:metadata, "missing required keys for #{event_type}/#{source}: #{missing.join(', ')}")
  end

  METADATA_REQUIRED_KEYS = {
    %w[stage_changed system] => %w[trigger],
    %w[stage_changed macro] => %w[macro_id macro_name],
    %w[closure_cancelled system] => %w[reason],
    %w[macro_triggered macro] => %w[macro_id macro_name]
  }.freeze

  def required_metadata_keys
    METADATA_REQUIRED_KEYS[[event_type, source]] || []
  end
end
