require 'rails_helper'

RSpec.describe Trigger, type: :model do
  describe 'CRUD operations' do
    it 'can be created' do
      trigger = described_class.create(companyId: 1)
      expect(trigger).to be_persisted
    end

    it 'can be updated' do
      trigger = described_class.create(companyId: 1)
      trigger.update(companyId: 2)
      expect(trigger.companyId).to eq(2)
    end

    it 'can be destroyed' do
      trigger = described_class.create(companyId: 1)
      expect { trigger.destroy }.to change(described_class, :count).by(-1)
    end
  end

  describe 'scopes' do
    describe '.by_company_ids' do
      let!(:trigger1) { create(:trigger, companyId: 1) }
      let!(:trigger2) { create(:trigger, companyId: 2) }
      let!(:trigger3) { create(:trigger, companyId: 3) }

      it 'returns triggers with the specified company ids' do
        result = described_class.by_company_ids([1, 2])
        expect(result).to include(trigger1, trigger2)
        expect(result).not_to include(trigger3)
      end
    end
  end
end
