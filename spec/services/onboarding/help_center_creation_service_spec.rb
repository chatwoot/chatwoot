require 'rails_helper'

RSpec.describe Onboarding::HelpCenterCreationService do
  let(:account) { create(:account, custom_attributes: { 'website' => 'user-confirmed.com' }) }
  let!(:admin) { create(:user, account: account, role: :administrator) }

  describe 'article generation enqueue' do
    context 'when account has a custom_attributes website' do
      it 'creates a HelpCenterGeneration row' do
        expect { described_class.new(account, admin).perform }
          .to change { account.help_center_generations.count }.by(1)
      end
    end

    context 'when account has only a brand_info domain' do
      let(:account) { create(:account, custom_attributes: { 'brand_info' => { 'domain' => 'enrichment.com' } }) }

      it 'creates a HelpCenterGeneration row using the enrichment fallback' do
        expect { described_class.new(account, admin).perform }
          .to change { account.help_center_generations.count }.by(1)
      end
    end

    context 'when account has no website url' do
      let(:account) { create(:account, custom_attributes: {}) }

      it 'does not create a HelpCenterGeneration row' do
        expect { described_class.new(account, admin).perform }
          .not_to(change { account.help_center_generations.count })
      end
    end

    context 'when a portal already exists' do
      before { create(:portal, account_id: account.id) }

      it 'does not create a HelpCenterGeneration row' do
        expect { described_class.new(account, admin).perform }
          .not_to(change { account.help_center_generations.count })
      end
    end
  end
end
