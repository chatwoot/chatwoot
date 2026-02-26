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
require 'rails_helper'

RSpec.describe CsatSurveyResponse do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:rating) }
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:contact_id) }

    it 'validates that the rating can only be in range 1-5' do
      csat_survey_response = build(:csat_survey_response, rating: 6)
      expect(csat_survey_response.valid?).to be false
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:contact) }
  end

  describe 'validates_factory' do
    it 'creates valid csat_survey_response object' do
      csat_survey_response = create(:csat_survey_response)
      expect(csat_survey_response.valid?).to be true
    end
  end
end
