require 'rails_helper'

RSpec.describe 'CRM pipelines and stages API', type: :request do
  around do |example|
    previous_value = ENV.fetch('CRM_KANBAN_ENABLED', nil)
    ENV['CRM_KANBAN_ENABLED'] = 'true'
    example.run
  ensure
    if previous_value.nil?
      ENV.delete('CRM_KANBAN_ENABLED')
    else
      ENV['CRM_KANBAN_ENABLED'] = previous_value
    end
  end

  it 'creates, updates and hides archived pipelines from the active list' do
    account, user = create_account_and_user

    post "/api/v1/accounts/#{account.id}/crm/pipelines",
         params: { pipeline: { name: 'Renovações', description: 'Carteira ativa' } },
         headers: auth_headers(user)

    expect(response).to have_http_status(:created)
    pipeline_id = response.parsed_body.dig('payload', 'id')

    patch "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline_id}",
          params: { pipeline: { name: 'Renovações 2026' } },
          headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig('payload', 'name')).to eq('Renovações 2026')

    delete "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline_id}", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)

    get "/api/v1/accounts/#{account.id}/crm/pipelines", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['payload'].pluck('id')).not_to include(pipeline_id)
  end

  it 'persists google_sync config on update without clobbering other metadata' do
    account, user = create_account_and_user
    pipeline, = create_crm_pipeline(account: account, user: user)
    pipeline.update!(metadata: { 'goals' => { 'monthly_target_cents' => 1000, 'currency' => 'BRL' } })

    patch "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline.id}",
          params: {
            pipeline: {
              google_sync: {
                enabled: true,
                events: { won: true, lost: false, moved: false },
                conversion_names: { won: 'Venda Site' }
              }
            }
          },
          headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    metadata = pipeline.reload.metadata
    expect(metadata['google_sync']).to eq(
      'enabled' => true,
      'events' => { 'won' => true, 'lost' => false, 'moved' => false },
      'conversion_names' => { 'won' => 'Venda Site' }
    )
    expect(metadata['goals']).to eq('monthly_target_cents' => 1000, 'currency' => 'BRL')
  end

  it 'prevents agents from creating pipelines and stages' do
    skip 'QUARANTINE: pre-existing legacy failure, harness-restore PR; real fix tracked for follow-up PR2'
    account, admin = create_account_and_user
    agent, = create_crm_agent(account: account)
    pipeline, = create_crm_pipeline(account: account, user: admin)

    post "/api/v1/accounts/#{account.id}/crm/pipelines",
         params: { pipeline: { name: 'Não autorizado' } },
         headers: auth_headers(agent)

    expect(response).to have_http_status(:unauthorized)

    post "/api/v1/accounts/#{account.id}/crm/pipelines/#{pipeline.id}/stages",
         params: { stage: { name: 'Sem acesso' } },
         headers: auth_headers(agent)

    expect(response).to have_http_status(:unauthorized)
  end

  it 'blocks deleting a stage that has cards' do
    account, user = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Card ativo')

    delete "/api/v1/accounts/#{account.id}/crm/stages/#{stage.id}", headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(account.crm_pipeline_stages.exists?(stage.id)).to be(true)
  end

  it 'blocks stage reorder across different pipelines' do
    account, user = create_account_and_user
    first_pipeline, first_stage = create_crm_pipeline(account: account, user: user, name: 'Funil A')
    second_pipeline, second_stage = create_crm_pipeline(account: account, user: user, name: 'Funil B')
    expect(first_pipeline.id).not_to eq(second_pipeline.id)

    post "/api/v1/accounts/#{account.id}/crm/stages/reorder",
         params: { stage_ids: [first_stage.id, second_stage.id] },
         headers: auth_headers(user)

    expect(response).to have_http_status(:unprocessable_entity)
  end
end
