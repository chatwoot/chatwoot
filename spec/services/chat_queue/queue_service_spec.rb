require 'rails_helper'

RSpec.describe ChatQueue::QueueService do
  let(:account) { create(:account, queue_enabled: true) }
  let(:inbox) { create(:inbox, account: account) }
  let(:service) { described_class.new(account: account) }
  let(:agent) { create(:user, account: account, availability: :online) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending, assignee: nil) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)

    allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return(
      { agent.id.to_s => 'online' }
    )
  end

  describe '#add_to_queue' do
    context 'when conversation is valid for queue' do
      it 'adds conversation to queue' do
        expect do
          service.add_to_queue(conversation)
        end.to change(ConversationQueue, :count).by(1)

        queue_entry = ConversationQueue.last
        expect(queue_entry.conversation_id).to eq(conversation.id)
        expect(queue_entry.account_id).to eq(account.id)
        expect(queue_entry.inbox_id).to eq(inbox.id)
        expect(queue_entry.status).to eq('waiting')
      end

      it 'returns true' do
        expect(service.add_to_queue(conversation)).to be true
      end

      it 'sets position automatically' do
        service.add_to_queue(conversation)
        expect(ConversationQueue.last.position).to eq(1)
      end
    end

    context 'when conversation is already in queue' do
      before do
        create(:conversation_queue, conversation: conversation, account: account, inbox: inbox, status: :waiting)
      end

      it 'returns false and does not add duplicate' do
        expect do
          result = service.add_to_queue(conversation)
          expect(result).to be false
        end.not_to(change(ConversationQueue, :count))
      end
    end

    context 'when queue is disabled for account' do
      before { account.update!(queue_enabled: false) }

      it 'returns false and does not add to queue' do
        expect do
          result = service.add_to_queue(conversation)
          expect(result).to be false
        end.not_to(change(ConversationQueue, :count))
      end
    end

    context 'when conversation is already assigned' do
      let(:assigned_conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent, status: :open) }

      it 'still adds to queue (ValidationService does not check assignee)' do
        expect do
          result = service.add_to_queue(assigned_conversation)
          expect(result).to be true
        end.to change(ConversationQueue, :count).by(1)
      end
    end
  end

  describe '#assign_from_queue' do
    context 'when queue is disabled' do
      before { account.update!(queue_enabled: false) }

      it 'returns nil without assigning' do
        create(:conversation_queue, conversation: conversation, account: account, inbox: inbox, status: :waiting)

        expect(service.assign_from_queue(inbox.id)).to be_nil
        expect(conversation.reload.assignee).to be_nil
      end
    end

    context 'when queue is empty' do
      it 'returns nil' do
        expect(service.assign_from_queue(inbox.id)).to be_nil
      end
    end

    context 'when no agents are available' do
      before do
        allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return(
          { agent.id.to_s => 'offline' }
        )
        create(:conversation_queue, conversation: conversation, account: account, inbox: inbox, status: :waiting)
      end

      it 'returns nil and conversation stays in queue' do
        expect(service.assign_from_queue(inbox.id)).to be_nil
        expect(conversation.reload.assignee).to be_nil
        expect(ConversationQueue.exists?(conversation_id: conversation.id, status: :waiting)).to be true
      end
    end

    context 'when agent is available' do
      let!(:queue_entry) { create(:conversation_queue, conversation: conversation, account: account, inbox: inbox, status: :waiting) }

      it 'assigns conversation to agent' do
        result = service.assign_from_queue(inbox.id)

        expect(result).not_to be_nil
        expect(conversation.reload.assignee).to eq(agent)
        expect(conversation.status).to eq('open')
      end

      it 'updates queue entry to assigned status' do
        service.assign_from_queue(inbox.id)

        expect(queue_entry.reload.status).to eq('assigned')
        expect(queue_entry.assigned_at).not_to be_nil
      end
    end

    context 'with multiple conversations in same priority group' do
      let(:conversation2) { create(:conversation, account: account, inbox: inbox, status: :pending, assignee: nil) }
      let(:conversation3) { create(:conversation, account: account, inbox: inbox, status: :pending, assignee: nil) }

      before do
        create(:conversation_queue, conversation: conversation, account: account, inbox: inbox, status: :waiting)
        create(:conversation_queue, conversation: conversation2, account: account, inbox: inbox, status: :waiting)
        create(:conversation_queue, conversation: conversation3, account: account, inbox: inbox, status: :waiting)
      end

      it 'assigns conversation with lowest position first' do
        service.assign_from_queue(inbox.id)

        expect(conversation.reload.assignee).to eq(agent)
        expect(conversation2.reload.assignee).to be_nil
        expect(conversation3.reload.assignee).to be_nil
      end
    end

    context 'with priority groups' do
      let(:vip_group) { create(:priority_group, account: account, name: 'VIP') }
      let(:regular_group) { create(:priority_group, account: account, name: 'Regular') }
      let(:vip_inbox) { create(:inbox, account: account, priority_group: vip_group) }
      let(:regular_inbox) { create(:inbox, account: account, priority_group: regular_group) }

      let(:vip_conversation) { create(:conversation, account: account, inbox: vip_inbox, status: :pending, assignee: nil) }
      let(:regular_conversation) { create(:conversation, account: account, inbox: regular_inbox, status: :pending, assignee: nil) }

      before do
        create(:inbox_member, inbox: vip_inbox, user: agent)
        create(:inbox_member, inbox: regular_inbox, user: agent)

        create(:conversation_queue, conversation: regular_conversation, account: account, inbox: regular_inbox, status: :waiting)
        create(:conversation_queue, conversation: vip_conversation, account: account, inbox: vip_inbox, status: :waiting)
      end

      it 'assigns from VIP inbox when requesting VIP inbox' do
        result = service.assign_from_queue(vip_inbox.id)

        expect(result).not_to be_nil
        expect(vip_conversation.reload.assignee).to eq(agent)
        expect(regular_conversation.reload.assignee).to be_nil
      end

      it 'assigns from regular inbox when requesting regular inbox' do
        result = service.assign_from_queue(regular_inbox.id)

        expect(result).not_to be_nil
        expect(regular_conversation.reload.assignee).to eq(agent)
        expect(vip_conversation.reload.assignee).to be_nil
      end
    end
  end

  describe '#assign_specific_from_queue!' do
    let!(:queue_entry) { create(:conversation_queue, conversation: conversation, account: account, inbox: inbox, status: :waiting) }

    context 'when queue is disabled' do
      before { account.update!(queue_enabled: false) }

      it 'returns nil' do
        expect(service.assign_specific_from_queue!(agent, conversation.id)).to be_nil
      end
    end

    context 'when agent is offline' do
      before do
        allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return(
          { agent.id.to_s => 'offline' }
        )
      end

      it 'returns nil' do
        expect(service.assign_specific_from_queue!(agent, conversation.id)).to be_nil
      end
    end

    context 'when conversation is not in queue' do
      let(:other_conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }

      it 'returns nil' do
        expect(service.assign_specific_from_queue!(agent, other_conversation.id)).to be_nil
      end
    end

    context 'when agent does not have access to inbox' do
      let(:other_inbox) { create(:inbox, account: account) }
      let(:other_conversation) { create(:conversation, account: account, inbox: other_inbox, status: :pending, assignee: nil) }

      before do
        create(:conversation_queue, conversation: other_conversation, account: account, inbox: other_inbox, status: :waiting)
      end

      it 'returns nil' do
        expect(service.assign_specific_from_queue!(agent, other_conversation.id)).to be_nil
      end
    end

    context 'when all conditions are met' do
      it 'assigns conversation to specific agent' do
        result = service.assign_specific_from_queue!(agent, conversation.id)

        expect(result).not_to be_nil
        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'updates queue entry to assigned' do
        service.assign_specific_from_queue!(agent, conversation.id)

        expect(queue_entry.reload.status).to eq('assigned')
        expect(queue_entry.assigned_at).not_to be_nil
      end
    end
  end

  describe '#remove_from_queue' do
    let!(:queue_entry) { create(:conversation_queue, conversation: conversation, account: account, inbox: inbox, status: :waiting) }

    it 'marks queue entry as left' do
      service.remove_from_queue(conversation)

      expect(queue_entry.reload.status).to eq('left')
      expect(queue_entry.left_at).not_to be_nil
    end

    it 'does not delete the queue entry' do
      expect do
        service.remove_from_queue(conversation)
      end.not_to(change(ConversationQueue, :count))
    end

    it 'does not affect conversation status' do
      original_status = conversation.status
      service.remove_from_queue(conversation)
      expect(conversation.reload.status).to eq(original_status)
    end
  end

  describe '#online_agents_list' do
    let(:agent2) { create(:user, account: account, availability: :online) }
    let(:agent3) { create(:user, account: account, availability: :offline) }

    before do
      allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return(
        {
          agent.id.to_s => 'online',
          agent2.id.to_s => 'online',
          agent3.id.to_s => 'offline'
        }
      )
    end

    it 'returns list of online agent ids' do
      result = service.online_agents_list

      expect(result).to be_an(Array)
      expect(result).to include(agent.id)
      expect(result).to include(agent2.id)
      expect(result).not_to include(agent3.id)
    end
  end

  describe '#queue_size' do
    let(:other_inbox) { create(:inbox, account: account) }

    before do
      3.times do
        conv = create(:conversation, account: account, inbox: inbox, status: :pending, assignee: nil)
        create(:conversation_queue, conversation: conv, account: account, inbox: inbox, status: :waiting)
      end

      2.times do
        conv = create(:conversation, account: account, inbox: other_inbox, status: :pending, assignee: nil)
        create(:conversation_queue, conversation: conv, account: account, inbox: other_inbox, status: :waiting)
      end
    end

    it 'returns queue size for specific priority group' do
      total_size = service.queue_size(inbox.id)
      expect(total_size).to eq(5)
    end

    context 'with different priority groups' do
      let(:vip_group) { create(:priority_group, account: account, name: 'VIP') }
      let(:regular_group) { create(:priority_group, account: account, name: 'Regular') }
      let(:vip_inbox) { create(:inbox, account: account, priority_group: vip_group) }
      let(:regular_inbox) { create(:inbox, account: account, priority_group: regular_group) }

      before do
        2.times do
          conv = create(:conversation, account: account, inbox: vip_inbox, status: :pending, assignee: nil)
          create(:conversation_queue, conversation: conv, account: account, inbox: vip_inbox, status: :waiting)
        end

        3.times do
          conv = create(:conversation, account: account, inbox: regular_inbox, status: :pending, assignee: nil)
          create(:conversation_queue, conversation: conv, account: account, inbox: regular_inbox, status: :waiting)
        end
      end

      it 'returns correct size for VIP group' do
        expect(service.queue_size(vip_inbox.id)).to eq(2)
      end

      it 'returns correct size for regular group' do
        expect(service.queue_size(regular_inbox.id)).to eq(3)
      end
    end
  end

  describe '#priority_group_for_inbox' do
    let(:priority_group) { create(:priority_group, account: account, name: 'vip') }

    before do
      inbox.update!(priority_group: priority_group)
    end

    it 'returns priority group object for inbox' do
      result = service.priority_group_for_inbox(inbox.id)
      expect(result).to eq(priority_group)
    end
  end

  describe 'complete queue workflow' do
    it 'adds conversation to queue, then assigns to agent' do
      expect(service.add_to_queue(conversation)).to be true
      expect(ConversationQueue.where(conversation_id: conversation.id, status: :waiting).count).to eq(1)

      result = service.assign_from_queue(inbox.id)
      expect(result).not_to be_nil

      expect(conversation.reload.assignee).to eq(agent)
      expect(ConversationQueue.where(conversation_id: conversation.id, status: :assigned).count).to eq(1)
    end

    it 'handles multiple assignments correctly' do
      conversations = []
      5.times do
        conv = create(:conversation, account: account, inbox: inbox, status: :pending, assignee: nil)
        conversations << conv
      end

      agents = [agent]
      2.times do
        a = create(:user, account: account, availability: :online)
        create(:inbox_member, inbox: inbox, user: a)
        agents << a
      end

      online_statuses = agents.map { |a| [a.id.to_s, 'online'] }.to_h
      allow(OnlineStatusTracker).to receive(:get_available_users).with(account.id).and_return(online_statuses)

      conversations.each { |c| service.add_to_queue(c) }
      expect(ConversationQueue.where(status: :waiting).count).to eq(5)

      results = Array.new(3) { service.assign_from_queue(inbox.id) }

      expect(results.compact.size).to eq(3)
      expect(ConversationQueue.where(status: :waiting).count).to eq(2)

      assigned_count = Conversation.where(id: conversations.map(&:id)).where.not(assignee: nil).count
      expect(assigned_count).to eq(3)
    end
  end

  describe 'edge cases' do
    it 'handles adding same conversation twice' do
      service.add_to_queue(conversation)

      expect(service.add_to_queue(conversation)).to be false
      expect(ConversationQueue.where(conversation_id: conversation.id).count).to eq(1)
    end

    it 'handles removing conversation not in queue' do
      expect do
        service.remove_from_queue(conversation)
      end.not_to raise_error
    end

    it 'handles assigning when conversation was removed from queue' do
      create(:conversation_queue, conversation: conversation, account: account, inbox: inbox, status: :waiting)

      service.remove_from_queue(conversation)

      expect(service.assign_from_queue(inbox.id)).to be_nil
    end

    it 'tracks wait time correctly' do
      service.add_to_queue(conversation)
      queue_entry = ConversationQueue.find_by(conversation_id: conversation.id)

      sleep 1

      service.assign_from_queue(inbox.id)
      queue_entry.reload

      expect(queue_entry.wait_time_seconds).to be >= 1
    end
  end
end
