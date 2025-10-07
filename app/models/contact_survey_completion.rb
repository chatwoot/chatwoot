# == Schema Information
#
# Table name: contact_survey_completions
#
#  id           :bigint           not null, primary key
#  completed_at :datetime         not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  contact_id   :bigint           not null
#  survey_id    :bigint           not null
#
# Indexes
#
#  idx_on_account_id_completed_at_5f0c3174ed       (account_id,completed_at)
#  index_contact_survey_completions_on_account_id  (account_id)
#  index_contact_survey_completions_on_contact_id  (contact_id)
#  index_contact_survey_completions_on_survey_id   (survey_id)
#  index_contact_survey_completions_unique         (contact_id,survey_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (survey_id => surveys.id)
#

class ContactSurveyCompletion < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :survey

  validates :account_id, presence: true
  validates :contact_id, presence: true
  validates :survey_id, presence: true
  validates :completed_at, presence: true

  scope :completed_between, ->(start_date, end_date) { where(completed_at: start_date..end_date) }
  scope :by_survey, ->(survey_id) { where(survey_id: survey_id) }
end
