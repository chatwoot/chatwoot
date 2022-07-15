require 'rails_helper'

describe RoundRobin::ManageService do
  subject(:round_robin_manage_service) { described_class.new(inbox: inbox) }

  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:inbox_members) { create_list(:inbox_member, 5, inbox: inbox) }

  describe '#available_agent' do
    it 'returns nil if allowed_member_ids is empty' do
      expect(described_class.new(inbox: inbox, allowed_member_ids: []).available_agent).to be_nil
    end

    it 'gets the first available agent in allowed_member_ids and move agent to end of the list' do
      expected_queue = [inbox_members[0].user_id, inbox_members[4].user_id, inbox_members[3].user_id, inbox_members[2].user_id,
                        inbox_members[1].user_id].map(&:to_s)
      described_class.new(inbox: inbox, allowed_member_ids: [inbox_members[0].user_id, inbox_members[4].user_id]).available_agent
      expect(round_robin_manage_service.send(:queue)).to eq(expected_queue)
    end

    it 'gets intersection of priority list and agent queue. get and move agent to the end of the list' do
      expected_queue = [inbox_members[2].user_id, inbox_members[4].user_id, inbox_members[3].user_id, inbox_members[1].user_id,
                        inbox_members[0].user_id].map(&:to_s)
      # prority list will be ids in string, since thats what redis supplies to us
      expect(described_class.new(inbox: inbox, allowed_member_ids: [inbox_members[2].user_id])
        .available_agent(priority_list: [inbox_members[3].user_id.to_s, inbox_members[2].user_id.to_s])).to eq inbox_members[2].user
      expect(round_robin_manage_service.send(:queue)).to eq(expected_queue)
    end

    it 'constructs round_robin_queue if queue is not present' do
      round_robin_manage_service.clear_queue
      expect(round_robin_manage_service.send(:queue)).to eq([])
      round_robin_manage_service.available_agent
      # the service constructed the redis queue before performing
      expect(round_robin_manage_service.send(:queue).sort.map(&:to_i)).to eq(inbox_members.map(&:user_id).sort)
    end

    it 'validates the queue and correct it before performing round robin' do
      # adding some invalid ids to queue
      round_robin_manage_service.add_agent_to_queue([2, 3, 5, 9])
      expect(round_robin_manage_service.send(:queue).sort.map(&:to_i)).not_to eq(inbox_members.map(&:user_id).sort)
      round_robin_manage_service.available_agent
      # the service have refreshed the redis queue before performing
      expect(round_robin_manage_service.send(:queue).sort.map(&:to_i)).to eq(inbox_members.map(&:user_id).sort)
    end

    context 'when allowed_member_ids is passed' do
      it 'will get the first allowed member and move it to the end of the queue' do
        expected_queue = [inbox_members[3].user_id, inbox_members[2].user_id, inbox_members[4].user_id, inbox_members[1].user_id,
                          inbox_members[0].user_id].map(&:to_s)
        expect(described_class.new(inbox: inbox,
                                   allowed_member_ids: [inbox_members[3].user_id,
                                                        inbox_members[2].user_id]).available_agent).to eq inbox_members[2].user
        expect(described_class.new(inbox: inbox,
                                   allowed_member_ids: [inbox_members[3].user_id,
                                                        inbox_members[2].user_id]).available_agent).to eq inbox_members[3].user
        expect(round_robin_manage_service.send(:queue)).to eq(expected_queue)
      end

      it 'will get union of priority list and allowed_member_ids and move it to the end of the queue' do
        expected_queue = [inbox_members[3].user_id, inbox_members[4].user_id, inbox_members[2].user_id, inbox_members[1].user_id,
                          inbox_members[0].user_id].map(&:to_s)
        # prority list will be ids in string, since thats what redis supplies to us
        expect(described_class.new(inbox: inbox,
                                   allowed_member_ids: [inbox_members[3].user_id,
                                                        inbox_members[2].user_id])
                                    .available_agent(
                                      priority_list: [inbox_members[3].user_id.to_s]
                                    )).to eq inbox_members[3].user
        expect(round_robin_manage_service.send(:queue)).to eq(expected_queue)
      end
    end
  end
end
