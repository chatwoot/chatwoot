require 'rails_helper'

RSpec.describe Crm::FollowUps::AutoFollowupRunner do
  def setup_followup(account:, user:)
    inbox = create_crm_whatsapp_api_inbox(account: account, members: [user])
    contact = account.contacts.create!(name: 'Lead', phone_number: "+55119#{rand(10_000_000..99_999_999)}")
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact, assignee: user)
    create_incoming_message(conversation: conversation)
    pipeline, stage = create_crm_pipeline(account: account, user: user)
    card = account.crm_cards.create!(
      pipeline: pipeline, stage: stage, inbox: inbox, contact: contact,
      primary_conversation: conversation, title: 'Lead'
    )
    account.crm_follow_ups.create!(
      card: card, conversation: conversation, title: 'Retomar', due_at: 10.minutes.ago, timezone: 'UTC',
      automation_mode: :auto_send_message, created_by: user,
      metadata: { source: 'ai_followup', touch: 1, message_body: 'Olá' }
    )
  end

  # (B) CREDENTIAL FAIL-CLOSED: a nil credential must become a rescued transient
  # (Result :failed with a retry_at), NOT an unrescued NoMethodError from
  # ResponsesClient dereferencing a nil @credential.
  it 'returns a rescued transient failure (not a NoMethodError) when the credential is nil' do
    account, user = create_account_and_user
    follow_up = setup_followup(account: account, user: user)
    allow(Crm::Ai::CredentialResolver).to receive(:new)
      .and_return(instance_double(Crm::Ai::CredentialResolver, resolve: nil))

    result = nil
    expect { result = described_class.new(follow_up: follow_up, now: Time.current).perform }.not_to raise_error

    expect(result.status).to eq(:failed)
    expect(result.retry_at).to be_present
    expect(follow_up.reload.metadata['retries']).to eq(1)
  end

  # Control: with a present credential the compose path runs normally — the guard
  # does not misfire — and a "don't send" composition yields a clean :skipped.
  it 'composes normally when the credential is present and skips on a no-send decision' do
    account, user = create_account_and_user
    follow_up = setup_followup(account: account, user: user)
    allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(
      instance_double(Crm::Ai::CredentialResolver,
                      resolve: { api_key: 'sk-test', api_base: 'https://api.openai.com', source: :system })
    )
    allow(Crm::Ai::FollowUpComposer).to receive(:new)
      .and_return(instance_double(Crm::Ai::FollowUpComposer, perform: { 'should_send' => false }))

    result = described_class.new(follow_up: follow_up, now: Time.current).perform

    expect(result.status).to eq(:skipped)
  end
end
