require 'rails_helper'

RSpec.describe 'Enterprise CSAT Survey Responses API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:csat_survey_response) { create(:csat_survey_response, account: account) }

  describe 'PATCH /api/v1/accounts/{account.id}/csat_survey_responses/:id' do
    let(:update_params) { { csat_review_notes: 'Customer was very satisfied with the resolution' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/csat_survey_responses/#{csat_survey_response.id}",
              params: update_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent without permissions' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/csat_survey_responses/#{csat_survey_response.id}",
              headers: agent.create_new_auth_token,
              params: update_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'updates the csat survey response review notes' do
        freeze_time do
          patch "/api/v1/accounts/#{account.id}/csat_survey_responses/#{csat_survey_response.id}",
                headers: administrator.create_new_auth_token,
                params: update_params,
                as: :json

          expect(response).to have_http_status(:success)
          csat_survey_response.reload
          expect(csat_survey_response.csat_review_notes).to eq('Customer was very satisfied with the resolution')
          expect(csat_survey_response.review_notes_updated_by).to eq(administrator)
          expect(csat_survey_response.review_notes_updated_at).to eq(Time.current)
        end
      end
    end

    context 'when it is an agent with report_manage permission' do
      let(:custom_role) { create(:custom_role, account: account, permissions: ['report_manage']) }
      let(:agent_with_role) { create(:user) }

      before do
        create(:account_user, user: agent_with_role, account: account, role: :agent, custom_role: custom_role)
      end

      it 'updates the csat survey response review notes' do
        freeze_time do
          patch "/api/v1/accounts/#{account.id}/csat_survey_responses/#{csat_survey_response.id}",
                headers: agent_with_role.create_new_auth_token,
                params: update_params,
                as: :json

          expect(response).to have_http_status(:success)
          csat_survey_response.reload
          expect(csat_survey_response.csat_review_notes).to eq('Customer was very satisfied with the resolution')
          expect(csat_survey_response.review_notes_updated_by).to eq(agent_with_role)
          expect(csat_survey_response.review_notes_updated_at).to eq(Time.current)
        end
      end
    end

    context 'when csat survey response does not exist' do
      it 'returns not found' do
        patch "/api/v1/accounts/#{account.id}/csat_survey_responses/0",
              headers: administrator.create_new_auth_token,
              params: update_params,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
