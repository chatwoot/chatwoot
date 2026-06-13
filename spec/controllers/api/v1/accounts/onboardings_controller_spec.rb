require 'rails_helper'

RSpec.describe 'Onboarding API', type: :request do
  let(:account) { create(:account, domain: 'example.com') }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'PATCH /api/v1/accounts/{account.id}/onboarding' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/onboarding", params: { website: 'acme.com' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as an agent (non-admin)' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized and does not change the account' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { name: 'Hijacked', website: 'attacker.com' },
              headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(account.reload.name).not_to eq('Hijacked')
      end

      it 'does not create a help center portal' do
        account.update!(custom_attributes: { 'onboarding_step' => 'account_details' })

        expect do
          patch "/api/v1/accounts/#{account.id}/onboarding",
                params: { website: 'attacker.com' },
                headers: agent.create_new_auth_token, as: :json
        end.not_to change(account.portals, :count)
      end
    end

    context 'when finalizing account_details' do
      before { account.update!(custom_attributes: { 'onboarding_step' => 'account_details' }) }

      it 'saves name and locale' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { name: 'Acme Inc', locale: 'fr' },
              headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.name).to eq('Acme Inc')
        expect(account.locale).to eq('fr')
      end

      it 'merges custom_attributes' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'acme.com', industry: 'tech', company_size: '10-50' },
              headers: admin.create_new_auth_token, as: :json

        attrs = account.reload.custom_attributes
        expect(attrs['website']).to eq('acme.com')
        expect(attrs['industry']).to eq('tech')
        expect(attrs['company_size']).to eq('10-50')
      end

      it 'clears onboarding_step' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'acme.com' },
              headers: admin.create_new_auth_token, as: :json

        expect(account.reload.custom_attributes).not_to have_key('onboarding_step')
      end

      it 'invokes HelpCenterCreationService when website is present', skip: 'help center generation wiring disabled until UI is ready' do
        service = instance_double(Onboarding::HelpCenterCreationService, perform: nil)
        allow(Onboarding::HelpCenterCreationService).to receive(:new).and_return(service)

        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'acme.com' },
              headers: admin.create_new_auth_token, as: :json

        expect(Onboarding::HelpCenterCreationService).to have_received(:new) do |arg_account, arg_user|
          expect(arg_account.id).to eq(account.id)
          expect(arg_user.id).to eq(admin.id)
        end
        expect(service).to have_received(:perform)
      end

      it 'does not create a help center portal when website is blank' do
        expect do
          patch "/api/v1/accounts/#{account.id}/onboarding",
                params: { name: 'Acme Inc' },
                headers: admin.create_new_auth_token, as: :json
        end.not_to change(account.portals, :count)
      end
    end

    context 'when onboarding_step is not account_details' do
      before { account.update!(custom_attributes: { 'onboarding_step' => 'invite_team' }) }

      it 'does not clear onboarding_step' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'acme.com' },
              headers: admin.create_new_auth_token, as: :json

        expect(account.reload.custom_attributes['onboarding_step']).to eq('invite_team')
      end

      it 'does not create a help center portal' do
        expect do
          patch "/api/v1/accounts/#{account.id}/onboarding",
                params: { website: 'acme.com' },
                headers: admin.create_new_auth_token, as: :json
        end.not_to change(account.portals, :count)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/onboarding/help_center_generation' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/onboarding/help_center_generation", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as an agent (non-admin)' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/onboarding/help_center_generation",
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when no help center generation has started' do
      it 'returns not_started with zero counts' do
        get "/api/v1/accounts/#{account.id}/onboarding/help_center_generation",
            headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to include(
          'generation_id' => nil,
          'state' => nil,
          'articles_count' => 0,
          'categories_count' => 0
        )
      end
    end
  end
end
