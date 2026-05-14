require 'rails_helper'

RSpec.describe Onboarding::HelpCenterCreationService do
  let(:account) { create(:account, custom_attributes: { 'website' => 'user-confirmed.com' }) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let(:generation_id) { 'generation-123' }

  before do
    allow(SecureRandom).to receive(:uuid).and_return(generation_id)
  end

  describe 'article generation enqueue' do
    context 'when account has a custom_attributes website' do
      it 'stores pending onboarding state and enqueues generation' do
        expect { described_class.new(account, admin).perform }
          .to have_enqueued_job(Onboarding::HelpCenterArticleGenerationJob)
          .with(account.id, kind_of(Integer), admin.id, generation_id)

        expect(account.reload.custom_attributes.dig('onboarding', 'help_center_generation')).to eq(
          'id' => generation_id,
          'status' => 'pending'
        )
      end
    end

    context 'when account has only a brand_info domain' do
      let(:account) { create(:account, custom_attributes: { 'brand_info' => { 'domain' => 'enrichment.com' } }) }

      it 'uses the enrichment fallback and enqueues generation' do
        expect { described_class.new(account, admin).perform }
          .to have_enqueued_job(Onboarding::HelpCenterArticleGenerationJob)
          .with(account.id, kind_of(Integer), admin.id, generation_id)
      end
    end

    context 'when account has no website url' do
      let(:account) { create(:account, custom_attributes: {}) }

      it 'does not enqueue generation' do
        expect { described_class.new(account, admin).perform }
          .not_to have_enqueued_job(Onboarding::HelpCenterArticleGenerationJob)

        expect(account.reload.custom_attributes.dig('onboarding', 'help_center_generation')).to be_nil
      end
    end

    context 'when a portal already exists' do
      before { create(:portal, account_id: account.id) }

      it 'does not enqueue generation' do
        expect { described_class.new(account, admin).perform }
          .not_to have_enqueued_job(Onboarding::HelpCenterArticleGenerationJob)

        expect(account.reload.custom_attributes.dig('onboarding', 'help_center_generation')).to be_nil
      end
    end
  end
end
