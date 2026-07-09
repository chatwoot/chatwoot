require 'rails_helper'

RSpec.describe Crm::StageAutomations::Runner do
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

  def create_automation(account:, stage:, user:, trigger_event:, steps:)
    automation = account.crm_stage_automations.create!(
      pipeline: stage.pipeline,
      stage: stage,
      name: "Rule #{trigger_event}",
      trigger_event: trigger_event,
      created_by: user
    )
    steps.each_with_index do |attrs, index|
      automation.steps.create!(
        account: account,
        position: index,
        delay_seconds: attrs[:delay_seconds] || 0,
        action_type: attrs[:action_type],
        action_config: attrs[:action_config] || {}
      )
    end
    automation
  end

  # Reason (CHANGED from fail-closed): the account has NO reporting_timezone, so
  # the create_follow_up step used to raise Unresolvable through ParamsResolver and
  # the automation execution would fail. It must now complete and persist the
  # follow-up anchored to the São Paulo default.
  it 'runs on_enter automations and creates a follow-up defaulting to America/Sao_Paulo when no account tz is set' do
    account, admin = create_account_and_user
    account.update!(reporting_timezone: nil)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Lead')

    create_automation(
      account: account,
      stage: stage,
      user: admin,
      trigger_event: :on_enter,
      steps: [
        {
          action_type: :create_follow_up,
          action_config: { title: 'Retornar contato', automation_mode: 'reminder_only' }
        }
      ]
    )

    described_class.new(
      card: card,
      actor: admin,
      from_stage_id: stage.id,
      to_stage_id: stage.id
    ).perform

    follow_up = account.crm_follow_ups.last
    expect(follow_up.title).to eq('Retornar contato')
    expect(follow_up.metadata['source']).to eq('stage_automation')
    expect(follow_up.timezone).to eq('America/Sao_Paulo')
    expect(account.crm_stage_automation_executions.completed.count).to eq(1)
  end

  it 'runs on_exit automations when leaving a stage' do
    account, admin = create_account_and_user
    agent, = create_crm_agent(account: account)
    pipeline, first_stage = create_crm_pipeline(account: account, user: admin)
    second_stage = create_crm_stage(account: account, pipeline: pipeline, name: 'Proposta', position: 1)
    card = account.crm_cards.create!(pipeline: pipeline, stage: first_stage, title: 'Lead')

    create_automation(
      account: account,
      stage: first_stage,
      user: admin,
      trigger_event: :on_exit,
      steps: [
        {
          action_type: :assign_owner,
          action_config: { owner_id: agent.id }
        }
      ]
    )

    Crm::Cards::Mover.new(card: card, actor: admin, target_stage: second_stage).perform

    expect(card.reload.owner_id).to eq(agent.id)
    expect(account.crm_stage_automation_executions.completed.count).to eq(1)
  end

  it 'does not rerun the same automation for the same trigger token' do
    account, admin = create_account_and_user
    account.update!(reporting_timezone: 'America/Sao_Paulo')
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Lead')

    create_automation(
      account: account,
      stage: stage,
      user: admin,
      trigger_event: :on_enter,
      steps: [
        {
          action_type: :create_follow_up,
          action_config: { title: 'Uma vez', automation_mode: 'reminder_only' }
        }
      ]
    )

    runner = described_class.new(
      card: card,
      actor: admin,
      from_stage_id: stage.id,
      to_stage_id: stage.id
    )
    runner.perform
    runner.perform

    expect(account.crm_follow_ups.count).to eq(1)
    expect(account.crm_stage_automation_executions.count).to eq(1)
  end

  it 'skips disabled automations' do
    account, admin = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    card = account.crm_cards.create!(pipeline: pipeline, stage: stage, title: 'Lead')

    automation = create_automation(
      account: account,
      stage: stage,
      user: admin,
      trigger_event: :on_enter,
      steps: [
        {
          action_type: :create_follow_up,
          action_config: { title: 'Desligada', automation_mode: 'reminder_only' }
        }
      ]
    )
    automation.update!(enabled: false)

    described_class.new(
      card: card,
      actor: admin,
      from_stage_id: stage.id,
      to_stage_id: stage.id
    ).perform

    expect(account.crm_follow_ups.count).to eq(0)
  end
end
