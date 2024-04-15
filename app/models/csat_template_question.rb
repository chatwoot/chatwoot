# == Schema Information
#
# Table name: csat_template_questions
#
#  id               :bigint           not null, primary key
#  content          :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  csat_template_id :bigint           not null
#
# Indexes
#
#  index_csat_template_questions_on_csat_template_id  (csat_template_id)
#
class CsatTemplateQuestion < ApplicationRecord
  belongs_to :csat_template, optional: true
  has_many :csat_survey_responses, dependent: :nullify

  def self.load_by_content(content)
    question = find_or_initialize_by(content: content)

    if question.new_record?
      question.csat_template_id = 0
      question.save
    end

    question.reload
  end
end
