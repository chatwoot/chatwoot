require 'rails_helper'

RSpec.describe Crm::Ai::HandoffEscalationJob do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:invited_agent) { create(:user, account: account) }
  let(:escalation_user) { create(:user, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:inbox) do
    # Auto-assignment nativo desligado: com a presença stubada como online, o
    # RoundRobin atribuiria a conversa na criação e o job pularia (already_assigned).
    create_crm_inbox(account: account, members: [invited_agent, escalation_user])
      .tap { |created| created.update!(enable_auto_assignment: false) }
  end
  let(:conversation) { create_crm_conversation(account: account, inbox: inbox, contact: contact) }
  let(:notification_builder) { instance_double(NotificationBuilder, perform: true) }

  around do |example|
    with_modified_env CRM_KANBAN_ENABLED: 'true', CRM_AI_ENABLED: 'true' do
      example.run
    end
  end

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    # Presença padrão: supervisor online (o gate de escalação exige online
    # quando prefer_online está ligado, que é o default do funil).
    allow(OnlineStatusTracker).to receive(:get_available_users)
      .with(account.id).and_return(escalation_user.id.to_s => 'online')
  end

  it 'assigns the escalation user and stamps the cycle when escalation_action is escalate' do
    card = create_card(
      config: base_config.merge('escalation_action' => 'escalate', 'escalation_user_id' => escalation_user.id),
      metadata: handoff_metadata(invited_at: 2.hours.ago)
    )

    expect(NotificationBuilder).not_to receive(:new)

    described_class.perform_now

    cycle = current_cycle(card.reload)
    expect(conversation.reload.assignee_id).to eq(escalation_user.id)
    expect(cycle['escalated_at']).to be_present
    expect(cycle['escalated_to']).to eq(escalation_user.id)
    expect(card.activities.where(event_type: 'ai_handoff_escalation')).to exist
  end

  it 'renotifies the originally invited agent without assigning or closing the cycle' do
    card = create_card(
      config: base_config.merge('escalation_action' => 'renotify'),
      metadata: handoff_metadata(invited_at: 2.hours.ago)
    )

    expect_handoff_notification(invited_agent)

    described_class.perform_now

    cycle = current_cycle(card.reload)
    expect(conversation.reload.assignee_id).to be_nil
    expect(cycle['renotified_at']).to be_present
    expect(cycle['renotify_count']).to eq(1)
    expect(cycle).not_to include('escalated_at', 'picked_up_at', 'canceled_at', 'expired_at')
    expect(ConversationParticipant.exists?(conversation: conversation, user: invited_agent)).to be(true)
    expect(card.activities.where(event_type: 'ai_handoff_renotify')).to exist
  end

  it 'does not renotify again before renotify_after_seconds elapses' do
    renotified_at = 30.minutes.ago
    card = create_card(
      config: base_config.merge('escalation_action' => 'renotify', 'renotify_after_seconds' => 3600),
      metadata: handoff_metadata(
        invited_at: 2.hours.ago,
        cycle_extra: { 'renotified_at' => renotified_at.iso8601, 'renotify_count' => 1 }
      )
    )

    expect(NotificationBuilder).not_to receive(:new)

    described_class.perform_now

    cycle = current_cycle(card.reload)
    expect(cycle['renotify_count']).to eq(1)
    expect(Time.zone.parse(cycle['renotified_at'])).to be_within(1.second).of(renotified_at)
  end

  it 'does not renotify after the maximum renotify count is reached' do
    renotified_at = 2.hours.ago
    card = create_card(
      config: base_config.merge('escalation_action' => 'renotify'),
      metadata: handoff_metadata(
        invited_at: 3.hours.ago,
        cycle_extra: {
          'renotified_at' => renotified_at.iso8601,
          'renotify_count' => Crm::Ai::Config::HANDOFF_RENOTIFY_MAX
        }
      )
    )

    expect(NotificationBuilder).not_to receive(:new)

    described_class.perform_now

    cycle = current_cycle(card.reload)
    expect(cycle['renotify_count']).to eq(Crm::Ai::Config::HANDOFF_RENOTIFY_MAX)
    expect(Time.zone.parse(cycle['renotified_at'])).to be_within(1.second).of(renotified_at)
  end

  it 'skips renotify for legacy cycles without invited_agent_id' do
    card = create_card(
      config: base_config.merge('escalation_action' => 'renotify'),
      metadata: handoff_metadata(invited_at: 2.hours.ago, invited_agent_id: nil)
    )

    expect(NotificationBuilder).not_to receive(:new)

    described_class.perform_now

    cycle = current_cycle(card.reload)
    expect(cycle['renotified_at']).to be_blank
    expect(cycle['renotify_count']).to be_blank
  end

  it 'preserves legacy escalation when escalation_user_id exists without explicit escalation_action' do
    card = create_card(
      config: base_config.except('escalation_action').merge('escalation_user_id' => escalation_user.id),
      metadata: handoff_metadata(invited_at: 2.hours.ago)
    )

    expect(NotificationBuilder).not_to receive(:new)

    described_class.perform_now

    cycle = current_cycle(card.reload)
    expect(conversation.reload.assignee_id).to eq(escalation_user.id)
    expect(cycle['escalated_at']).to be_present
    expect(cycle['escalated_to']).to eq(escalation_user.id)
  end

  it 'holds the escalation while the supervisor is offline and prefer_online is on' do
    allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return({})
    card = create_card(
      config: base_config.merge('escalation_action' => 'escalate', 'escalation_user_id' => escalation_user.id),
      metadata: handoff_metadata(invited_at: 2.hours.ago)
    )

    described_class.perform_now

    cycle = current_cycle(card.reload)
    expect(conversation.reload.assignee_id).to be_nil
    expect(cycle['escalated_at']).to be_blank
  end

  it 'forces the escalation to an offline supervisor when prefer_online is off' do
    allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return({})
    card = create_card(
      config: base_config.merge(
        'escalation_action' => 'escalate', 'escalation_user_id' => escalation_user.id, 'prefer_online' => false
      ),
      metadata: handoff_metadata(invited_at: 2.hours.ago)
    )

    described_class.perform_now

    expect(conversation.reload.assignee_id).to eq(escalation_user.id)
    expect(current_cycle(card.reload)['escalated_at']).to be_present
  end

  def base_config
    {
      'enabled' => true,
      'handoff_mode' => 'r3_invite',
      'pickup_threshold_seconds' => 60,
      'renotify_after_seconds' => 60
    }
  end

  def create_card(config:, metadata:)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    stage.update!(metadata: { 'ai_handoff' => config })
    account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      inbox: inbox,
      contact: contact,
      primary_conversation: conversation,
      title: 'Lead com convite R3',
      metadata: metadata
    )
  end

  def handoff_metadata(invited_at:, invited_agent_id: invited_agent.id, cycle_extra: {})
    cycle = {
      'cycle_id' => 1,
      'invited_at' => invited_at.iso8601
    }.merge(cycle_extra)
    cycle['invited_agent_id'] = invited_agent_id if invited_agent_id.present?

    {
      'ai' => {
        'handoffs' => [cycle],
        'handoff' => cycle
      }
    }
  end

  def current_cycle(card)
    card.metadata.dig('ai', 'handoffs').first
  end

  def expect_handoff_notification(agent)
    expect(NotificationBuilder).to receive(:new).with(
      notification_type: 'conversation_handoff_request',
      user: agent,
      account: account,
      primary_actor: conversation,
      secondary_actor: nil
    ).and_return(notification_builder)
  end
end
