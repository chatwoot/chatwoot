require 'rails_helper'

RSpec.describe Ticket do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:ticket) { create(:ticket, account: account, conversation: conversation) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:created_by).optional }
  end

  describe 'validations' do
    it 'requires a subject' do
      expect(build(:ticket, subject: nil)).not_to be_valid
    end

    it 'allows only one ticket per conversation' do
      ticket
      duplicate = build(:ticket, account: account, conversation: conversation)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:conversation_id]).to be_present
    end
  end

  describe '#status_category' do
    it 'is closed when the conversation is resolved and the ticket is closed' do
      ticket.update!(closed_at: Time.current)
      conversation.update!(status: :resolved)

      expect(ticket.reload.status_category).to eq('closed')
    end

    it 'is done when the conversation is resolved and the ticket is not closed' do
      conversation.update!(status: :resolved)

      expect(ticket.reload.status_category).to eq('done')
    end

    it 'is waiting when the ticket is waiting on someone' do
      ticket.update!(waiting_on: :customer)

      expect(ticket.status_category).to eq('waiting')
    end

    it 'is waiting when the conversation is snoozed' do
      conversation.update!(status: :snoozed, snoozed_until: 1.day.from_now)

      expect(ticket.reload.status_category).to eq('waiting')
    end

    it 'is triage when the conversation is open and unassigned' do
      expect(ticket.status_category).to eq('triage')
    end

    it 'is in_progress when the conversation is open and assigned to an agent' do
      conversation.update!(assignee: create(:user, account: account, role: :agent))

      expect(ticket.reload.status_category).to eq('in_progress')
    end

    it 'is in_progress when the conversation is handled by an agent bot' do
      conversation.update!(assignee_agent_bot: create(:agent_bot, account: account))

      expect(ticket.reload.status_category).to eq('in_progress')
    end

    it 'is in_progress when the conversation is pending' do
      conversation.update!(status: :pending)

      expect(ticket.reload.status_category).to eq('in_progress')
    end
  end

  describe '#open_tasks_count' do
    it 'counts only the open tasks' do
      create(:ticket_task, ticket: ticket, account: account)
      create(:ticket_task, ticket: ticket, account: account, status: :done)

      expect(ticket.open_tasks_count).to eq(1)
    end
  end

  describe '#push_event_data' do
    it 'exposes the conversation display id and the derived category' do
      create(:ticket_task, ticket: ticket, account: account)
      data = ticket.push_event_data

      expect(data[:id]).to eq(ticket.id)
      expect(data[:conversation_id]).to eq(conversation.display_id)
      expect(data[:subject]).to eq(ticket.subject)
      expect(data[:status_category]).to eq('triage')
      expect(data[:waiting_on]).to eq('none')
      expect(data[:open_tasks_count]).to eq(1)
    end
  end

  describe '#webhook_data' do
    it 'adds a slim conversation payload' do
      data = ticket.webhook_data

      expect(data[:conversation]).to eq(
        { id: conversation.display_id, inbox_id: conversation.inbox_id, status: conversation.status }
      )
      expect(data[:account]).to eq(account.webhook_data)
    end
  end

  describe 'events' do
    it 'dispatches ticket.created' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      new_ticket = create(:ticket, account: account, conversation: conversation)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Events::Types::TICKET_CREATED, kind_of(Time), hash_including(ticket: new_ticket))
    end

    it 'dispatches ticket.updated when a tracked attribute changes' do
      ticket
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      ticket.update!(waiting_on: :internal)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Events::Types::TICKET_UPDATED, kind_of(Time), hash_including(ticket: ticket))
    end

    it 'does not dispatch ticket.updated when nothing meaningful changes' do
      ticket
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      ticket.touch # rubocop:disable Rails/SkipsModelValidations

      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
        .with(Events::Types::TICKET_UPDATED, any_args)
    end
  end

  describe 'activity messages' do
    it 'records an activity message on creation' do
      expect { create(:ticket, account: account, conversation: conversation, subject: 'Refund request') }
        .to have_enqueued_job(Conversations::ActivityMessageJob)
    end

    it 'records an activity message when waiting_on changes' do
      ticket

      expect { ticket.update!(waiting_on: :customer) }
        .to have_enqueued_job(Conversations::ActivityMessageJob)
    end
  end
end
