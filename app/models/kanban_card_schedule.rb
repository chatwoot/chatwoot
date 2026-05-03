# == Schema Information
#
# Table name: kanban_card_schedules
#
#  id             :bigint           not null, primary key
#  description    :text
#  scheduled_at   :datetime         not null
#  status         :integer          default("pending"), not null
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  created_by_id  :bigint           not null
#  kanban_card_id :bigint           not null
#
# Indexes
#
#  index_kanban_card_schedules_on_created_by_id              (created_by_id)
#  index_kanban_card_schedules_on_kanban_card_id             (kanban_card_id)
#  index_kanban_card_schedules_on_kanban_card_id_and_status  (kanban_card_id,status)
#  index_kanban_card_schedules_on_scheduled_at               (scheduled_at)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (kanban_card_id => kanban_cards.id)
#
class KanbanCardSchedule < ApplicationRecord
  belongs_to :kanban_card
  belongs_to :created_by, class_name: 'User'

  enum :status, { pending: 0, triggered: 1, cancelled: 2 }

  validates :title, presence: true
  validates :scheduled_at, presence: true
  validate :scheduled_at_in_future, on: :create

  after_create :enqueue_trigger_job

  private

  def scheduled_at_in_future
    return unless scheduled_at.present? && scheduled_at <= Time.current

    errors.add(:scheduled_at, I18n.t('errors.kanban.schedule.scheduled_at.future', default: 'must be in the future'))
  end

  def enqueue_trigger_job
    KanbanScheduleTriggerJob.set(wait_until: scheduled_at).perform_later(id)
  end
end
