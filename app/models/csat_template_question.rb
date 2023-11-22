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
  belongs_to :csat_template
  has_many :csat_survey_responses, dependent: :nullify
end
