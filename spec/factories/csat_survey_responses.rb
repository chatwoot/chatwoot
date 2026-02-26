# frozen_string_literal: true

# == Schema Information
#
# Table name: csat_survey_responses
#
#  id                :bigint           not null, primary key
#  feedback_message  :text
#  rating            :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  assigned_agent_id :bigint
#  contact_id        :bigint           not null
#  conversation_id   :bigint           not null
#  message_id        :bigint           not null
#
# Indexes
#
#  index_csat_survey_responses_on_account_id         (account_id)
#  index_csat_survey_responses_on_assigned_agent_id  (assigned_agent_id)
#  index_csat_survey_responses_on_contact_id         (contact_id)
#  index_csat_survey_responses_on_conversation_id    (conversation_id)
#  index_csat_survey_responses_on_message_id         (message_id) UNIQUE
#
FactoryBot.define do
  factory :csat_survey_response do
    rating { 1 }
    feedback_message { Faker::Movie.quote }
    account
    conversation
    message
    contact
  end
end
