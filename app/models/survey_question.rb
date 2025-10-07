# == Schema Information
#
# Table name: survey_questions
#
#  id            :bigint           not null, primary key
#  input_type    :integer          default("text")
#  position      :integer          default(0), not null
#  question_text :text             not null
#  question_type :integer          default("open_ended"), not null
#  required      :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  survey_id     :bigint           not null
#
# Indexes
#
#  index_survey_questions_on_survey_id               (survey_id)
#  index_survey_questions_on_survey_id_and_position  (survey_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (survey_id => surveys.id)
#

class SurveyQuestion < ApplicationRecord
  belongs_to :survey
  has_many :survey_question_options, dependent: :destroy
  has_many :survey_answers, dependent: :destroy

  enum question_type: { open_ended: 0, multiple_choice: 1 }
  enum input_type: { text: 0, number: 1 }

  validates :question_text, presence: true, length: { maximum: 500 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :validate_options_for_multiple_choice

  default_scope { order(position: :asc) }

  accepts_nested_attributes_for :survey_question_options, allow_destroy: true

  private

  def validate_options_for_multiple_choice
    return unless multiple_choice?

    return unless survey_question_options.reject(&:marked_for_destruction?).size < 2

    errors.add(:base, 'Multiple choice questions must have at least 2 options')
  end
end
