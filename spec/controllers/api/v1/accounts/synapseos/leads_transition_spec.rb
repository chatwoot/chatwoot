require 'rails_helper'

RSpec.describe 'Synapseos Leads transition API', type: :request do
  let(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let(:conversation) { create(:conversation, account: account) }
  let!(:stage_quer) do
    create(:synapseos_pipeline_stage, account: account, slug: 'aguardando_atendimento_humano',
                                      name: 'Aguardando atendimento humano', stage_type: 'working')
  end
  let!(:stage_encerrado) do
    create(:synapseos_pipeline_stage, account: account, slug: 'encerrado', name: 'Encerrado', stage_type: 'lost')
  end

  describe 'POST /api/v1/accounts/:account_id/synapseos/leads/transition' do
    let(:url) { "/api/v1/accounts/#{account.id}/synapseos/leads/transition" }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post url, params: { conversation_id: conversation.display_id, signal: 'quer' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'creates the lead if missing and applies the signal, resolving by display_id' do
        post url,
             headers: admin.create_new_auth_token,
             params: {
               conversation_id: conversation.display_id,
               signal: 'quer',
               fields: { modelo_interesse: 'A4', tem_troca: true, forma_pagamento: 'financiamento', urgencia: 'alta' }
             },
             as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['estado']).to eq('quer')
        expect(body['modelo_interesse']).to eq('A4')
        expect(body['tem_troca']).to be(true)
        expect(body['next_action_at']).to be_present

        lead = Synapseos::Lead.find_by(account_id: account.id, conversation_id: conversation.id)
        expect(lead.estado).to eq('quer')
      end

      it 'resolves the conversation on a nao_quer with motivo' do
        post url,
             headers: admin.create_new_auth_token,
             params: { conversation_id: conversation.display_id, signal: 'nao_quer', motivo: 'sem interesse' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['estado']).to eq('nao_quer')
        expect(conversation.reload.status).to eq('resolved')
      end

      it 'returns 422 when nao_quer is sent without motivo' do
        post url,
             headers: admin.create_new_auth_token,
             params: { conversation_id: conversation.display_id, signal: 'nao_quer' },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 422 for an unknown signal' do
        post url,
             headers: admin.create_new_auth_token,
             params: { conversation_id: conversation.display_id, signal: 'explode' },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 404 when the conversation cannot be resolved' do
        post url,
             headers: admin.create_new_auth_token,
             params: { conversation_id: 99_999_999, signal: 'quer' },
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # Guard: o endpoint legado upsert_by_conversation NÃO foi alterado.
  describe 'POST upsert_by_conversation still works' do
    it 'upserts without touching estado' do
      post "/api/v1/accounts/#{account.id}/synapseos/leads/upsert_by_conversation",
           headers: admin.create_new_auth_token,
           params: { conversation_id: conversation.display_id, stage_slug: 'encerrado' },
           as: :json

      expect(response).to have_http_status(:success)
      lead = Synapseos::Lead.find_by(account_id: account.id, conversation_id: conversation.id)
      expect(lead.pipeline_stage_id).to eq(stage_encerrado.id)
      expect(lead.estado).to be_nil
    end
  end
end
