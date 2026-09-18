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
              params: { name: 'Acme Inc', locale: 'fr', onboarding_step: 'account_details' },
              headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.name).to eq('Acme Inc')
        expect(account.locale).to eq('fr')
      end

      it 'merges custom_attributes' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'acme.com', industry: 'tech', company_size: '10-50', onboarding_step: 'account_details' },
              headers: admin.create_new_auth_token, as: :json

        attrs = account.reload.custom_attributes
        expect(attrs['website']).to eq('acme.com')
        expect(attrs['industry']).to eq('tech')
        expect(attrs['company_size']).to eq('10-50')
      end

      context 'when on cloud (inbox setup is a cloud-only step)' do
        before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true) }

        it 'advances onboarding_step to inbox_setup' do
          patch "/api/v1/accounts/#{account.id}/onboarding",
                params: { website: 'acme.com', onboarding_step: 'account_details' },
                headers: admin.create_new_auth_token, as: :json

          expect(account.reload.custom_attributes['onboarding_step']).to eq('inbox_setup')
        end

        it 'does not create a help center portal when website is blank' do
          expect do
            patch "/api/v1/accounts/#{account.id}/onboarding",
                  params: { name: 'Acme Inc', onboarding_step: 'account_details' },
                  headers: admin.create_new_auth_token, as: :json
          end.not_to change(account.portals, :count)
        end

        it 'is idempotent when the account_details completion is replayed' do
          2.times do
            patch "/api/v1/accounts/#{account.id}/onboarding",
                  params: { website: 'acme.com', onboarding_step: 'account_details' },
                  headers: admin.create_new_auth_token, as: :json
          end

          # Replaying step 1 always lands on inbox_setup; it never skips to done.
          expect(account.reload.custom_attributes['onboarding_step']).to eq('inbox_setup')
        end
      end

      context 'when off cloud (inbox setup is skipped)' do
        before { allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false) }

        it 'finishes onboarding instead of advancing to inbox_setup' do
          patch "/api/v1/accounts/#{account.id}/onboarding",
                params: { website: 'acme.com', onboarding_step: 'account_details' },
                headers: admin.create_new_auth_token, as: :json

          expect(account.reload.custom_attributes).not_to have_key('onboarding_step')
        end

        it 'does not auto-create onboarding inboxes' do
          expect(Onboarding::WebWidgetCreationService).not_to receive(:new)

          patch "/api/v1/accounts/#{account.id}/onboarding",
                params: { website: 'acme.com', onboarding_step: 'account_details' },
                headers: admin.create_new_auth_token, as: :json
        end
      end
    end

    context 'when replaying account_details after onboarding has finished' do
      before { account.update!(custom_attributes: { 'website' => 'acme.com' }) }

      it 'does not re-enter onboarding or persist the stale payload' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'stale.com', onboarding_step: 'account_details' },
              headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.custom_attributes).not_to have_key('onboarding_step')
        expect(account.custom_attributes['website']).to eq('acme.com')
      end
    end

    context 'when finalizing inbox_setup' do
      before { account.update!(custom_attributes: { 'onboarding_step' => 'inbox_setup' }) }

      it 'clears onboarding_step' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { onboarding_step: 'inbox_setup' },
              headers: admin.create_new_auth_token, as: :json

        expect(account.reload.custom_attributes).not_to have_key('onboarding_step')
      end

      it 'does not create another web widget inbox' do
        expect(Onboarding::WebWidgetCreationService).not_to receive(:new)

        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { onboarding_step: 'inbox_setup' },
              headers: admin.create_new_auth_token, as: :json
      end

      it 'is idempotent when the finalize request is replayed' do
        2.times do
          patch "/api/v1/accounts/#{account.id}/onboarding",
                params: { onboarding_step: 'inbox_setup' },
                headers: admin.create_new_auth_token, as: :json
        end

        expect(account.reload.custom_attributes).not_to have_key('onboarding_step')
      end
    end

    context 'when the declared onboarding_step is missing or unknown' do
      before { account.update!(custom_attributes: { 'onboarding_step' => 'invite_team' }) }

      it 'rejects a request without an onboarding_step and changes nothing' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { website: 'acme.com' },
              headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(account.reload.custom_attributes['onboarding_step']).to eq('invite_team')
        expect(account.custom_attributes['website']).to be_nil
      end

      it 'rejects an unknown onboarding_step' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { onboarding_step: 'invite_team' },
              headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create a help center portal' do
        expect do
          patch "/api/v1/accounts/#{account.id}/onboarding",
                params: { website: 'acme.com' },
                headers: admin.create_new_auth_token, as: :json
        end.not_to change(account.portals, :count)
      end
    end

    context 'when completing inbox_setup out of order' do
      before { account.update!(custom_attributes: { 'onboarding_step' => 'account_details' }) }

      it 'does not clear onboarding_step while the account is still on account_details' do
        patch "/api/v1/accounts/#{account.id}/onboarding",
              params: { onboarding_step: 'inbox_setup' },
              headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.custom_attributes['onboarding_step']).to eq('account_details')
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
