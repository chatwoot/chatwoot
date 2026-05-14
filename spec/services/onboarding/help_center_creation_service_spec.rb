require 'rails_helper'

RSpec.describe Onboarding::HelpCenterCreationService do
  let(:account) { create(:account, domain: 'example.com') }
  let!(:admin) { create(:user, account: account, role: :administrator) }

  describe 'article generation enqueue' do
    context 'when account has a website url' do
      it 'creates a HelpCenterGeneration row' do
        expect { described_class.new(account, admin).perform }
          .to change { account.help_center_generations.count }.by(1)
      end
    end

    context 'when account has no domain and no brand_info domain' do
      let(:account) { create(:account, domain: nil) }

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

    context 'when only custom_attributes website is set' do
      let(:account) do
        create(:account, domain: nil, custom_attributes: { 'website' => 'user-confirmed.com' })
      end

      it 'creates a HelpCenterGeneration row using the user-confirmed website' do
        expect { described_class.new(account, admin).perform }
          .to change { account.help_center_generations.count }.by(1)
      end
    end
  end
end
