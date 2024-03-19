require 'rails_helper'

RSpec.describe SlaEvent, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:applied_sla) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'validates_factory' do
    it 'creates valid sla event object' do
      sla_event = create(:sla_event)
      expect(sla_event.event_type).to eq 'frt'
    end
  end
end

# require 'rails_helper'

# RSpec.describe AppliedSla, type: :model do
#   describe 'associations' do
#     it { is_expected.to belong_to(:sla_policy) }
#     it { is_expected.to belong_to(:account) }
#     it { is_expected.to belong_to(:conversation) }
#   end

#   describe 'validates_factory' do
#     it 'creates valid applied sla policy object' do
#       applied_sla = create(:applied_sla)
#       expect(applied_sla.sla_status).to eq 'active'
#     end
#   end
# end
