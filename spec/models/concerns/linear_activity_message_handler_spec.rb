require 'rails_helper'

RSpec.describe LinearActivityMessageHandler, type: :model do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe '#create_linear_issue_created_activity' do
    it 'enqueues an activity message job when issue data contains id' do
      issue_data = { id: 'ENG-123' }

      expect do
        conversation.create_linear_issue_created_activity(issue_data)
      end.to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, {
                account_id: conversation.account_id,
                inbox_id: conversation.inbox_id,
                message_type: :activity,
                content: 'New Linear issue ENG-123 has been created'
              })
    end

    it 'does not enqueue job when issue data lacks id' do
      issue_data = { title: 'Some issue' }

      expect do
        conversation.create_linear_issue_created_activity(issue_data)
      end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
    end

    it 'does not enqueue job when issue_data is empty' do
      expect do
        conversation.create_linear_issue_created_activity({})
      end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
    end
  end

  describe '#create_linear_issue_linked_activity' do
    it 'enqueues an activity message job when issue data contains id' do
      issue_data = { id: 'ENG-456' }

      expect do
        conversation.create_linear_issue_linked_activity(issue_data)
      end.to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, {
                account_id: conversation.account_id,
                inbox_id: conversation.inbox_id,
                message_type: :activity,
                content: 'Linear issue ENG-456 is now linked'
              })
    end

    it 'does not enqueue job when issue data lacks id' do
      issue_data = { title: 'Some issue' }

      expect do
        conversation.create_linear_issue_linked_activity(issue_data)
      end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
    end

    it 'does not enqueue job when issue_data is empty' do
      expect do
        conversation.create_linear_issue_linked_activity({})
      end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
    end
  end

  describe '#create_linear_issue_unlinked_activity' do
    it 'enqueues an activity message job when issue data contains id' do
      issue_data = { id: 'ENG-789' }

      expect do
        conversation.create_linear_issue_unlinked_activity(issue_data)
      end.to have_enqueued_job(Conversations::ActivityMessageJob)
        .with(conversation, {
                account_id: conversation.account_id,
                inbox_id: conversation.inbox_id,
                message_type: :activity,
                content: 'Linear issue ENG-789 has been unlinked'
              })
    end

    it 'does not enqueue job when issue data lacks id' do
      issue_data = { title: 'Some issue' }

      expect do
        conversation.create_linear_issue_unlinked_activity(issue_data)
      end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
    end

    it 'does not enqueue job when issue_data is empty' do
      expect do
        conversation.create_linear_issue_unlinked_activity({})
      end.not_to have_enqueued_job(Conversations::ActivityMessageJob)
    end
  end
end