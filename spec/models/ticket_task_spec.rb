require 'rails_helper'

RSpec.describe TicketTask do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:ticket) { create(:ticket, account: account, conversation: conversation) }
  let(:task) { create(:ticket_task, account: account, ticket: ticket) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:ticket) }
    it { is_expected.to belong_to(:assignee).optional }
    it { is_expected.to belong_to(:team).optional }
    it { is_expected.to belong_to(:created_by).optional }
  end

  describe 'validations' do
    it 'requires a title' do
      expect(build(:ticket_task, ticket: ticket, account: account, title: nil)).not_to be_valid
    end
  end

  describe 'defaults' do
    it 'starts open and unassigned' do
      expect(task.status).to eq('open')
      expect(task.assignee_id).to be_nil
      expect(task.team_id).to be_nil
      expect(task.completed_at).to be_nil
    end
  end

  describe 'completed_at' do
    it 'is set when the task is marked done' do
      task.update!(status: :done)

      expect(task.reload.completed_at).to be_present
    end

    it 'is cleared when the task is reopened' do
      task.update!(status: :done)
      task.update!(status: :open)

      expect(task.reload.completed_at).to be_nil
    end

    it 'is left alone when other attributes change' do
      task.update!(status: :done)
      completed_at = task.reload.completed_at

      task.update!(title: 'Renamed')

      expect(task.reload.completed_at).to eq(completed_at)
    end
  end

  describe 'ticket association' do
    it 'is destroyed along with the ticket' do
      task

      expect { ticket.destroy! }.to change(described_class, :count).by(-1)
    end
  end

  describe 'events' do
    it 'dispatches ticket_task.completed when the task is done' do
      task
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      task.update!(status: :done)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Events::Types::TICKET_TASK_COMPLETED, kind_of(Time), ticket_task: task)
    end

    it 'does not dispatch when the task is only renamed' do
      task
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      task.update!(title: 'Renamed')

      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
        .with(Events::Types::TICKET_TASK_COMPLETED, any_args)
    end

    it 'records an activity message when the task is completed' do
      task

      expect { task.update!(status: :done) }.to have_enqueued_job(Conversations::ActivityMessageJob)
    end
  end
end
