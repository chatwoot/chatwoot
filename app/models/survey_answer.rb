# == Schema Information
#
# Table name: survey_answers
#
#  id                        :bigint           not null, primary key
#  answer_text               :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :bigint           not null
#  contact_id                :bigint           not null
#  survey_question_id        :bigint           not null
#  survey_question_option_id :bigint
#
# Indexes
#
#  index_survey_answers_on_account_id                         (account_id)
#  index_survey_answers_on_account_id_and_created_at          (account_id,created_at)
#  index_survey_answers_on_contact_id                         (contact_id)
#  index_survey_answers_on_contact_id_and_survey_question_id  (contact_id,survey_question_id) UNIQUE
#  index_survey_answers_on_survey_question_id                 (survey_question_id)
#  index_survey_answers_on_survey_question_option_id          (survey_question_option_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (survey_question_id => survey_questions.id)
#  fk_rails_...  (survey_question_option_id => survey_question_options.id)
#

class SurveyAnswer < ApplicationRecord
  belongs_to :account
  belongs_to :contact
  belongs_to :survey_question
  belongs_to :survey_question_option, optional: true

  validates :account_id, presence: true
  validates :contact_id, presence: true
  validates :survey_question_id, presence: true
  validate :answer_presence
  validate :answer_type_consistency

  private

  def answer_presence
    return if answer_text.present? || survey_question_option_id.present?

    errors.add(:base, 'Either answer_text or survey_question_option_id must be present')
  end

  def answer_type_consistency
    return unless survey_question

    if survey_question.open_ended? && survey_question_option_id.present?
      errors.add(:survey_question_option_id, 'should not be present for open-ended questions')
    elsif survey_question.multiple_choice? && answer_text.present?
      errors.add(:answer_text, 'should not be present for multiple choice questions')
    end
  end
end
