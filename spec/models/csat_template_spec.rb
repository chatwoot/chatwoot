require 'rails_helper'

RSpec.describe CsatTemplate do
  describe 'associations' do
    it { is_expected.to have_many(:inboxes) }
    it { is_expected.to have_many(:csat_template_questions) }
  end

  describe 'validates_factory' do
    it 'creates valid csat_template object' do
      csat_template = create(:csat_template)
      expect(csat_template.valid?).to be true
    end
  end
end
