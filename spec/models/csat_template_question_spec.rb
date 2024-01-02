require 'rails_helper'

RSpec.describe CsatTemplateQuestion do
  describe 'associations' do
    it { is_expected.to belong_to(:csat_template).optional }
  end

  describe 'validates_factory' do
    it 'creates valid csat_template_question object' do
      csat_template_question = create(:csat_template_question)
      expect(csat_template_question.valid?).to be true
    end
  end
end
