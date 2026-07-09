require 'rails_helper'

RSpec.describe Crm::Conversations::CardSyncer do
  around do |example|
    previous_value = ENV.fetch('CRM_KANBAN_ENABLED', nil)
    previous_dedup_window = ENV.fetch('CRM_AUTO_CREATE_DEDUP_WINDOW_DAYS', nil)
    ENV['CRM_KANBAN_ENABLED'] = 'true'
    ENV.delete('CRM_AUTO_CREATE_DEDUP_WINDOW_DAYS')
    example.run
  ensure
    if previous_value.nil?
      ENV.delete('CRM_KANBAN_ENABLED')
    else
      ENV['CRM_KANBAN_ENABLED'] = previous_value
    end
    if previous_dedup_window.nil?
      ENV.delete('CRM_AUTO_CREATE_DEDUP_WINDOW_DAYS')
    else
      ENV['CRM_AUTO_CREATE_DEDUP_WINDOW_DAYS'] = previous_dedup_window
    end
  end

  before do
    allow(Crm::Cards::Broadcaster).to receive(:broadcast)
  end

  it 'does not create cards when the CRM feature flag is disabled' do
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead Sem Flag', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    message = create_crm_message(conversation: conversation, sender: contact)
    ENV['CRM_KANBAN_ENABLED'] = 'false'

    described_class.new(conversation: conversation, message: message).perform

    expect(account.crm_cards).to be_blank
    expect(Crm::Cards::Broadcaster).not_to have_received(:broadcast)
  end

  it 'does not create cards for inboxes without auto-create binding' do
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead Sem Auto', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: false, created_by: admin)
    message = create_crm_message(conversation: conversation, sender: contact)

    described_class.new(conversation: conversation, message: message).perform

    expect(account.crm_cards).to be_blank
  end

  it 'does not create cards when inbox CRM settings disable CRM' do
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead CRM Off', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    account.crm_inbox_settings.create!(inbox: inbox, crm_enabled: false, auto_create_card: true)
    message = create_crm_message(conversation: conversation, sender: contact)

    described_class.new(conversation: conversation, message: message).perform

    expect(account.crm_cards).to be_blank
  end

  it 'does not create cards when inbox CRM settings disable auto-create' do
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead Auto Off', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    account.crm_inbox_settings.create!(inbox: inbox, crm_enabled: true, auto_create_card: false)
    message = create_crm_message(conversation: conversation, sender: contact)

    described_class.new(conversation: conversation, message: message).perform

    expect(account.crm_cards).to be_blank
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates one hydrated card for an auto-create inbox binding' do
    account, admin = create_account_and_user
    agent, = create_crm_agent(account: account)
    team = account.teams.create!(name: 'Vendas')
    inbox = create_crm_inbox(account: account, members: [agent])
    contact = account.contacts.create!(name: 'Maria Auto', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: agent, team: team)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    message = create_crm_message(conversation: conversation, sender: contact)
    conversation.update!(assignee: agent, team: team)

    card = described_class.new(conversation: conversation, message: message).perform

    expect(card).to be_persisted
    expect(account.crm_cards.count).to eq(1)
    expect(card.pipeline_id).to eq(pipeline.id)
    expect(card.stage_id).to eq(stage.id)
    expect(card.contact_id).to eq(contact.id)
    expect(card.conversation_id).to eq(conversation.id)
    expect(card.inbox_id).to eq(inbox.id)
    expect(card.owner_id).to eq(agent.id)
    expect(card.team_id).to eq(team.id)
    expect(card.title).to eq('Maria Auto')
    expect(card.last_message_at.to_i).to eq(message.created_at.to_i)
    expect(card.metadata.dig('crm_auto_sync', 'source')).to eq('conversation_observer')
    expect(account.crm_card_conversations.where(card: card, conversation: conversation)).to exist
    expect(account.crm_activities.where(card: card, event_type: 'create')).to exist
    expect(Crm::Cards::Broadcaster).to have_received(:broadcast).with(card, Events::Types::CRM_CARD_CREATED)
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'reuses the same active card on retries' do
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead Retry', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    message = create_crm_message(conversation: conversation, sender: contact)

    first_card = described_class.new(conversation: conversation, message: message).perform
    second_card = described_class.new(conversation: conversation, message: message).perform

    expect(second_card.id).to eq(first_card.id)
    expect(account.crm_cards.where(conversation_id: conversation.id).count).to eq(1)
    expect(account.crm_card_conversations.where(conversation_id: conversation.id).count).to eq(1)
  end

  it 'reuses an open card with the same contact, inbox and pipeline inside the dedup window' do
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead Dedupe', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    existing_card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      contact: contact,
      inbox: inbox,
      owner: admin,
      title: 'Lead Dedupe Existente',
      last_activity_at: 2.days.ago
    )
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    message = create_crm_message(conversation: conversation, sender: contact)

    card = described_class.new(conversation: conversation, message: message).perform

    expect(card.id).to eq(existing_card.id)
    expect(account.crm_cards.open.where(contact: contact, inbox: inbox, pipeline: pipeline).count).to eq(1)
    expect(card.reload.conversation_id).to eq(conversation.id)
    expect(account.crm_card_conversations.where(card: card, conversation: conversation)).to exist
    expect(card.activities.where(event_type: 'conversation_dedup_reuse')).to exist
  end

  it 'does not reuse contact/inbox/pipeline cards outside the configured dedup window' do
    ENV['CRM_AUTO_CREATE_DEDUP_WINDOW_DAYS'] = '1'
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead Fora Janela', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    old_card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      contact: contact,
      inbox: inbox,
      title: 'Lead Antigo',
      last_activity_at: 3.days.ago
    )
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    message = create_crm_message(conversation: conversation, sender: contact)

    card = described_class.new(conversation: conversation, message: message).perform

    expect(card.id).not_to eq(old_card.id)
    expect(account.crm_cards.open.where(contact: contact, inbox: inbox, pipeline: pipeline).count).to eq(2)
  end

  it 'does not reuse won or lost cards for automatic creation' do
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead Fechado', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    lost_card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      contact: contact,
      inbox: inbox,
      title: 'Lead Perdido',
      status: :lost,
      last_activity_at: 1.hour.ago
    )
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    message = create_crm_message(conversation: conversation, sender: contact)

    card = described_class.new(conversation: conversation, message: message).perform

    expect(card.id).not_to eq(lost_card.id)
    expect(card).to be_open
    expect(account.crm_cards.where(contact: contact, inbox: inbox, pipeline: pipeline).count).to eq(2)
  end

  it 'refreshes an existing auto-created card when the conversation changes' do
    account, admin = create_account_and_user
    first_agent, = create_crm_agent(account: account, name: 'Primeiro agente')
    next_agent, = create_crm_agent(account: account, name: 'Segundo agente')
    team = account.teams.create!(name: 'Suporte')
    inbox = create_crm_inbox(account: account, members: [first_agent, next_agent])
    contact = account.contacts.create!(name: 'Lead Atualizado', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: first_agent)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    first_message = create_crm_message(conversation: conversation, sender: contact, content: 'Primeira mensagem')
    card = described_class.new(conversation: conversation, message: first_message).perform

    conversation.update!(assignee: next_agent, team: team)
    next_message = create_crm_message(conversation: conversation, sender: contact, content: 'Nova mensagem')
    conversation.update!(assignee: next_agent, team: team)
    described_class.new(conversation: conversation.reload, message: next_message).perform

    card.reload
    expect(card.owner_id).to eq(next_agent.id)
    expect(card.team_id).to eq(team.id)
    expect(card.last_message_at.to_i).to eq(next_message.created_at.to_i)
    expect(card.activities.where(event_type: 'conversation_sync')).to exist
    expect(Crm::Cards::Broadcaster).to have_received(:broadcast).with(card, Events::Types::CRM_CARD_UPDATED)
  end

  it 'prefers the inbox default pipeline when multiple auto-create bindings exist' do
    account, admin = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [admin])
    contact = account.contacts.create!(name: 'Lead Preferido', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: admin)
    first_pipeline, first_stage = create_crm_pipeline(account: account, user: admin, name: 'Funil A')
    second_pipeline, second_stage = create_crm_pipeline(account: account, user: admin, name: 'Funil B')
    account.crm_pipeline_inboxes.create!(
      pipeline: first_pipeline, inbox: inbox, default_stage: first_stage, auto_create_card: true, created_by: admin
    )
    account.crm_pipeline_inboxes.create!(
      pipeline: second_pipeline, inbox: inbox, default_stage: second_stage, auto_create_card: true, created_by: admin
    )
    account.crm_inbox_settings.create!(
      inbox: inbox,
      crm_enabled: true,
      auto_create_card: true,
      default_pipeline: second_pipeline,
      default_stage: second_stage
    )
    message = create_crm_message(conversation: conversation, sender: contact)

    card = described_class.new(conversation: conversation, message: message).perform

    expect(card.pipeline_id).to eq(second_pipeline.id)
    expect(card.stage_id).to eq(second_stage.id)
  end

  # Reason: assignee_changed/team_changed listeners enqueue CardSyncer with
  # message: nil (Crm::SyncConversationCardJob#perform default). Without a NEW
  # real message since the card was created, last_message_at/last_activity_at
  # must stay put — this was the root cause bug (fallback to conversation.
  # last_activity_at, which any system activity message bumps).
  it 'does not alter last_message_at/last_activity_at when syncing without a message' do
    account, admin = create_account_and_user
    agent, = create_crm_agent(account: account)
    inbox = create_crm_inbox(account: account, members: [agent])
    contact = account.contacts.create!(name: 'Lead Sem Mensagem Nova', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: agent)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    message = create_crm_message(conversation: conversation, sender: contact)
    card = described_class.new(conversation: conversation, message: message).perform
    original_last_message_at = card.last_message_at
    original_last_activity_at = card.last_activity_at

    other_agent, = create_crm_agent(account: account, name: 'Outro agente')
    conversation.update!(assignee: other_agent)
    described_class.new(conversation: conversation.reload, message: nil).perform

    card.reload
    expect(card.owner_id).to eq(other_agent.id)
    expect(card.last_message_at.to_i).to eq(original_last_message_at.to_i)
    expect(card.last_activity_at.to_i).to eq(original_last_activity_at.to_i)
  end

  # Reason: stage moves and linkers set last_activity_at to Time.current; a later
  # assignment sync (message: nil) deriving from the last real message would
  # regress that recent CRM activity back to an old message date, breaking
  # ordering and dedupe. The sync must leave both fields untouched.
  it 'does not regress a recent last_activity_at to an old real-message date on message-less sync' do
    account, admin = create_account_and_user
    agent, = create_crm_agent(account: account)
    inbox = create_crm_inbox(account: account, members: [agent])
    contact = account.contacts.create!(name: 'Lead Atividade Recente', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: agent)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    old_message = travel_to(5.days.ago) { create_crm_message(conversation: conversation, sender: contact, content: 'Mensagem antiga') }
    card = described_class.new(conversation: conversation, message: old_message).perform
    card.update!(last_activity_at: Time.current)
    recent_activity_at = card.reload.last_activity_at

    other_agent, = create_crm_agent(account: account, name: 'Outro agente')
    conversation.update!(assignee: other_agent)
    described_class.new(conversation: conversation.reload, message: nil).perform

    card.reload
    expect(card.last_activity_at.to_i).to eq(recent_activity_at.to_i)
    expect(card.last_message_at.to_i).to eq(old_message.created_at.to_i)
  end

  # Reason: a private note or an activity message (system-generated, e.g. an
  # assignment note) must never count as a real message even if it were ever
  # passed in as @message — CardSyncer derives last_message_at purely from
  # Message.chat on the conversation, ignoring @message's own timestamp.
  it 'does not count an activity message towards last_message_at' do
    account, admin = create_account_and_user
    agent, = create_crm_agent(account: account)
    inbox = create_crm_inbox(account: account, members: [agent])
    contact = account.contacts.create!(name: 'Lead Activity', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: agent)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_pipeline_inboxes.create!(pipeline: pipeline, inbox: inbox, default_stage: stage, auto_create_card: true, created_by: admin)
    real_message = travel_to(2.minutes.ago) { create_crm_message(conversation: conversation, sender: contact, content: 'Mensagem real') }
    card = described_class.new(conversation: conversation, message: real_message).perform

    activity_message = create_crm_message(
      conversation: conversation, sender: contact, content: 'Assignee mudou', message_type: :activity
    )
    described_class.new(conversation: conversation.reload, message: activity_message).perform

    card.reload
    expect(card.last_message_at.to_i).to eq(real_message.created_at.to_i)
    expect(card.last_message_at.to_i).not_to eq(activity_message.created_at.to_i)
  end

  def create_crm_message(conversation:, sender:, content: 'Olá', private: false, message_type: :incoming)
    conversation.messages.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      sender: sender,
      content: content,
      message_type: message_type,
      private: private
    )
  end
end
