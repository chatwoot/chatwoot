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

      it 'invokes HelpCenterCreationService when website is present' do
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

      it 'does not invoke HelpCenterCreationService when website is blank' do
        allow(Onboarding::HelpCenterCreationService).to receive(:new)

        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { name: 'Acme Inc' },
              headers: admin.create_new_auth_token, as: :json

        expect(Onboarding::HelpCenterCreationService).not_to have_received(:new)
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

      it 'does not invoke HelpCenterCreationService' do
        allow(Onboarding::HelpCenterCreationService).to receive(:new)

        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'acme.com' },
              headers: admin.create_new_auth_token, as: :json

        expect(Onboarding::HelpCenterCreationService).not_to have_received(:new)
      end
    end
  end
end
