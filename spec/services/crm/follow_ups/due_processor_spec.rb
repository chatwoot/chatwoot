require 'rails_helper'

RSpec.describe Crm::FollowUps::DueProcessor do
  it 'marks due pending follow-ups as overdue and reopens snoozed conversations' do
    account, user = create_account_and_user
    inbox = create_crm_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead Atrasado', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    conversation.update!(status: :snoozed, snoozed_until: 1.hour.ago)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      inbox: inbox,
      contact: contact,
      primary_conversation: conversation,
      title: 'Lead Atrasado'
    )
    follow_up = account.crm_follow_ups.create!(
      card: card,
      conversation: conversation,
      title: 'Reabrir',
      due_at: 10.minutes.ago,
      timezone: 'UTC',
      automation_mode: :snooze_conversation,
      created_by: user
    )

    allow(Crm::FollowUps::Broadcaster).to receive(:broadcast_due)

    described_class.new(now: Time.current).perform

    expect(follow_up.reload.status).to eq('overdue')
    expect(conversation.reload.status).to eq('open')
    expect(card.activities.where(event_type: 'follow_up_overdue')).to exist
    expect(Crm::FollowUps::Broadcaster).to have_received(:broadcast_due).with(follow_up)
  end

  it 'sends auto-send follow-ups and marks them done when delivery succeeds' do
    account, user = create_account_and_user
    inbox = create_crm_whatsapp_api_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead Auto', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    create_incoming_message(conversation: conversation)
    template = create_whatsapp_api_template(account: account, inbox: inbox, user: user)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      inbox: inbox,
      contact: contact,
      primary_conversation: conversation,
      title: 'Lead Auto'
    )
    follow_up = account.crm_follow_ups.create!(
      card: card,
      conversation: conversation,
      title: 'Enviar mensagem',
      due_at: 10.minutes.ago,
      timezone: 'UTC',
      automation_mode: :auto_send_message,
      created_by: user,
      metadata: {
        message_body: 'Olá, retorno combinado',
        whatsapp_api_message_template_id: template.id
      }
    )

    described_class.new(now: Time.current).perform

    expect(follow_up.reload.status).to eq('done')
    expect(card.activities.where(event_type: 'follow_up_message_sent')).to exist
    expect(card.reload.next_follow_up_at).to be_nil
  end

  # ---- helpers for the AI auto-follow-up branch ---------------------------
  def build_ai_followup(account:, user:, pipeline:, stage:, title:)
    due_at = 10.minutes.ago
    inbox = create_crm_whatsapp_api_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: title, phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    create_incoming_message(conversation: conversation)
    card = account.crm_cards.create!(
      pipeline: pipeline, stage: stage, inbox: inbox, contact: contact,
      primary_conversation: conversation, title: title
    )
    account.crm_follow_ups.create!(
      card: card, conversation: conversation, title: title, due_at: due_at, timezone: 'UTC',
      automation_mode: :auto_send_message, created_by: user,
      metadata: { source: 'ai_followup', touch: 1, message_body: 'Olá' }
    )
  end

  # (A) HEAD-OF-LINE CRASH: one follow_up whose runner raises must NOT abort the
  # sweep for the rest. The crashing row is left pending; the healthy row is still
  # processed to done in the same sweep.
  it 'keeps processing healthy follow-ups when one row raises during the sweep' do
    account, user = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    pipeline.update!(metadata: { 'ai' => { 'auto_followup' => { 'enabled' => true } } })
    allow(Crm::Ai::Config).to receive(:enabled?).and_return(true)

    crashing = build_ai_followup(account: account, user: user, pipeline: pipeline, stage: stage, title: 'Boom')
    healthy = build_ai_followup(account: account, user: user, pipeline: pipeline, stage: stage, title: 'Sadio')

    allow(Crm::FollowUps::AutoFollowupRunner).to receive(:new) do |follow_up:, now:| # rubocop:disable Lint/UnusedBlockArgument
      instance_double(Crm::FollowUps::AutoFollowupRunner).tap do |runner|
        if follow_up.id == crashing.id
          allow(runner).to receive(:perform).and_raise(StandardError, 'compose blew up')
        else
          allow(runner).to receive(:perform).and_return(Crm::FollowUps::AutoFollowupRunner::Result.sent(follow_up))
        end
      end
    end

    described_class.new(now: Time.current).perform

    expect(crashing.reload.status).to eq('pending')
    expect(healthy.reload.status).to eq('done')
  end

  # (C) KILL-SWITCH AT EXECUTION: with CRM_AI_ENABLED off, an ai_followup due row
  # is NOT dispatched to the runner and stays pending (resumes if re-enabled).
  it 'does not send ai_followup rows and leaves them pending when AI is disabled' do
    account, user = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    pipeline.update!(metadata: { 'ai' => { 'auto_followup' => { 'enabled' => true } } })
    allow(Crm::Ai::Config).to receive(:enabled?).and_return(false)

    follow_up = build_ai_followup(account: account, user: user, pipeline: pipeline, stage: stage, title: 'Desligado')

    expect(Crm::FollowUps::AutoFollowupRunner).not_to receive(:new)

    described_class.new(now: Time.current).perform

    expect(follow_up.reload.status).to eq('pending')
  end

  # (C control) with AI enabled AND the pipeline auto-follow-up enabled, the same
  # row routes to the runner exactly as before.
  it 'routes ai_followup rows to the runner when AI and the pipeline are enabled' do
    account, user = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    pipeline.update!(metadata: { 'ai' => { 'auto_followup' => { 'enabled' => true } } })
    allow(Crm::Ai::Config).to receive(:enabled?).and_return(true)

    follow_up = build_ai_followup(account: account, user: user, pipeline: pipeline, stage: stage, title: 'Ligado')

    runner = instance_double(Crm::FollowUps::AutoFollowupRunner,
                             perform: Crm::FollowUps::AutoFollowupRunner::Result.sent(follow_up))
    expect(Crm::FollowUps::AutoFollowupRunner).to receive(:new)
      .with(follow_up: follow_up, now: kind_of(Time)).and_return(runner)

    described_class.new(now: Time.current).perform

    expect(follow_up.reload.status).to eq('done')
  end

  it 'marks auto-send follow-ups done when the message was already sent' do
    account, user = create_account_and_user
    inbox = create_crm_whatsapp_api_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead Retry', phone_number: '+5511987654321')
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    create_incoming_message(conversation: conversation)
    template = create_whatsapp_api_template(account: account, inbox: inbox, user: user)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      inbox: inbox,
      contact: contact,
      primary_conversation: conversation,
      title: 'Lead Retry'
    )
    follow_up = account.crm_follow_ups.create!(
      card: card,
      conversation: conversation,
      title: 'Enviar mensagem',
      due_at: 10.minutes.ago,
      timezone: 'UTC',
      automation_mode: :auto_send_message,
      created_by: user,
      metadata: {
        message_body: 'Olá',
        whatsapp_api_message_template_id: template.id,
        sent_message_id: 42
      }
    )

    described_class.new(now: Time.current).perform

    expect(follow_up.reload.status).to eq('done')
  end
end
