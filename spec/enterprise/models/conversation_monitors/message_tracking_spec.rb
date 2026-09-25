require 'rails_helper'
require 'timeout'

RSpec.describe ConversationMonitors::MessageTracking do
  # Both connections must see committed setup while the message transaction remains open.
  self.use_transactional_tests = false

  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account, created_at: 3.days.ago, paused_at: 1.hour.ago) }
  let(:conversation) { create(:conversation, account: account, created_at: 1.day.ago) }

  before do
    account.enable_features!('reports', 'conversation_monitors')
    monitor.initial_scan.update!(enumerated_at: 2.hours.ago)
    conversation
  end

  after do
    users = account.users.to_a
    perform_enqueued_jobs(only: ActiveRecord::DestroyAssociationAsyncJob) do
      account.conversations.destroy_all
      account.contacts.destroy_all
      account.inboxes.destroy_all
      account.destroy!
      users.each(&:destroy!)
    end
  end

  %w[catch_up from_now].product(%i[incoming outgoing]).each do |mode, message_type|
    it "handles an uncommitted #{message_type} message when resuming with #{mode}" do
      inserted = Queue.new
      continue_commit = Queue.new
      writer = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Message.transaction do
            message = create(:message, account: account, conversation: conversation, message_type: message_type, content: 'Refund while paused')
            inserted << message.id
            Timeout.timeout(10) { continue_commit.pop }
          end
        end
      end

      begin
        message_id = Timeout.timeout(10) { inserted.pop }
        expect(Message.where(id: message_id)).not_to exist
        ConversationMonitors::Resume.new(monitor, mode: mode, collection_version: 0).perform
        scan = monitor.scans.find_by!(kind: mode)
        ConversationMonitors::ScanJob.perform_now(scan.id) if mode == 'catch_up'
        expect(scan.reload.enumerated_at).to be_present
        expect(monitor.evaluations).not_to exist

        continue_commit << true
        writer.value

        if mode == 'catch_up'
          expect(monitor.evaluations.sole).to have_attributes(status: 'pending', requested_version: monitor.collection_version)
          work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
          expect(work).to have_attributes(due_at: be_present, full_history_revision: be > work.processed_revision)
        else
          expect(monitor.evaluations).not_to exist
          expect(ConversationMonitors::WorkItem.where(conversation: conversation)).not_to exist
        end
      ensure
        continue_commit << true
        writer.join(15)
      end
    end
  end
end
