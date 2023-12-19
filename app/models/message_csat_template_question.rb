# == Schema Information
#
# Table name: message_csat_template_questions
#
#  id                        :bigint           not null, primary key
#  question_number           :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  csat_template_question_id :bigint
#  message_id                :bigint
#
# Indexes
#
#  index_messages_csat_question_id  (csat_template_question_id)
#  uniq_csat_question_messages_id   (message_id)
#
class MessageCsatTemplateQuestion < ApplicationRecord
  belongs_to :message
  belongs_to :csat_template_question
end
