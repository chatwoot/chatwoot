require 'rails_helper'

RSpec.describe CsatSurveyResponse, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:rating) }
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:contact_id) }

    it 'validates that the rating can only be in range 1-5' do
      csat_survey_response = build(:csat_survey_response, rating: 6)
      expect(csat_survey_response.valid?).to eq false
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
      expect(csat_survey_response.valid?).to eq true
    end
  end
end
