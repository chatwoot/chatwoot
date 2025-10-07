# == Schema Information
#
# Table name: survey_question_options
#
#  id                 :bigint           not null, primary key
#  option_text        :string           not null
#  position           :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  survey_question_id :bigint           not null
#
# Indexes
#
#  index_survey_question_options_on_question_and_position  (survey_question_id,position)
#  index_survey_question_options_on_survey_question_id     (survey_question_id)
#
# Foreign Keys
#
#  fk_rails_...  (survey_question_id => survey_questions.id)
#

class SurveyQuestionOption < ApplicationRecord
  belongs_to :survey_question
  has_many :survey_answers, dependent: :destroy

  validates :option_text, presence: true, length: { maximum: 255 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { order(position: :asc) }
end
