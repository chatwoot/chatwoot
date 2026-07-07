require 'rails_helper'

RSpec.describe 'Enterprise Onboarding API', type: :request do
  let(:account) { create(:account, domain: 'example.com') }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'PATCH /api/v1/accounts/{account.id}/onboarding' do
    context 'when finalizing account_details' do
      # Inbox/help-center setup is a cloud-only step; off cloud the flow finishes at account_details.
      before do
        account.update!(custom_attributes: { 'onboarding_step' => 'account_details' })
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      end

      it 'invokes HelpCenterCreationService when website is present' do
        service = instance_double(Onboarding::HelpCenterCreationService, perform: nil)
        allow(Onboarding::HelpCenterCreationService).to receive(:new).and_return(service)

        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'acme.com', onboarding_step: 'account_details' },
              headers: admin.create_new_auth_token, as: :json

        expect(Onboarding::HelpCenterCreationService).to have_received(:new) do |arg_account, arg_user|
          expect(arg_account.id).to eq(account.id)
          expect(arg_user.id).to eq(admin.id)
        end
        expect(service).to have_received(:perform)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/onboarding/help_center_generation' do
    context 'when help center generation is in progress' do
      let(:generation_id) { 'generation-123' }
      let!(:portal) { create(:portal, account_id: account.id) }
      let!(:category) { create(:category, portal: portal, account_id: account.id) }

      before do
        account.update!(custom_attributes: { 'help_center_generation_id' => generation_id })
        create(:article, portal: portal, category: category, account_id: account.id, author_id: admin.id)
        Onboarding::HelpCenterGenerationState.start(generation_id, total: 3)
        Onboarding::HelpCenterGenerationState.record_article_finished(generation_id)
      end

      after do
        Redis::Alfred.delete(Onboarding::HelpCenterGenerationState.key(generation_id))
      end

      it 'returns Redis state and help center counts' do
        get "/api/v1/accounts/#{account.id}/onboarding/help_center_generation",
            headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include(
          'generation_id' => generation_id,
          'articles_count' => 1,
          'categories_count' => 1
        )
        expect(response.parsed_body['state']).to include(
          'status' => 'generating',
          'finished' => '1',
          'total' => '3'
        )
      end
    end
  end
end
