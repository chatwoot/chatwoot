class Captain::Routine < ApplicationRecord
  self.table_name = 'captain_routines'

  belongs_to :account

  enum :status, {
    draft: 0,
    building: 1,
    awaiting_clarification: 2,
    ready: 3,
    needs_review: 4,
    failed: 5
  }, default: :draft, prefix: true

  validates :instructions, presence: true

  def build_dsl!(answers: {}, on_stage: nil)
    Captain::Routines::DslBuilderService.new(self, on_stage: on_stage).perform(answers: answers)
  end
end
