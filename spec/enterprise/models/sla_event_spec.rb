require 'rails_helper'

RSpec.describe SlaEvent, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:applied_sla) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:sla_policy) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'validates_factory' do
    it 'creates valid sla event object' do
      sla_event = create(:sla_event)
      expect(sla_event.event_type).to eq 'frt'
    end
  end
end
