require 'rails_helper'

describe RoundRobin::ManageService do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:inbox_members) { create_list(:inbox_member, 5, inbox: inbox) }
  let(:subject) { ::RoundRobin::ManageService.new(inbox: inbox) }

  describe '#available_agent' do
    it 'gets the first available agent and move agent to end of the list' do
      expected_queue = [inbox_members[0].user_id, inbox_members[4].user_id, inbox_members[3].user_id, inbox_members[2].user_id,
                        inbox_members[1].user_id].map(&:to_s)
      subject.available_agent
      expect(subject.send(:queue)).to eq(expected_queue)
    end

    it 'gets intersection of priority list and agent queue. get and move agent to the end of the list' do
      expected_queue = [inbox_members[2].user_id, inbox_members[4].user_id, inbox_members[3].user_id, inbox_members[1].user_id,
                        inbox_members[0].user_id].map(&:to_s)
      expect(subject.available_agent(priority_list: [inbox_members[3].user_id, inbox_members[2].user_id])).to eq inbox_members[2].user
      expect(subject.send(:queue)).to eq(expected_queue)
    end

    it 'constructs round_robin_queue if queue is not present' do
      subject.clear_queue
      expect(subject.send(:queue)).to eq([])
      subject.available_agent
      # the service constructed the redis queue before performing
      expect(subject.send(:queue).sort.map(&:to_i)).to eq(inbox_members.map(&:user_id).sort)
    end

    it 'validates the queue and correct it before performing round robin' do
      # adding some invalid ids to queue
      subject.add_agent_to_queue([2, 3, 5, 9])
      expect(subject.send(:queue).sort.map(&:to_i)).not_to eq(inbox_members.map(&:user_id).sort)
      subject.available_agent
      # the service have refreshed the redis queue before performing
      expect(subject.send(:queue).sort.map(&:to_i)).to eq(inbox_members.map(&:user_id).sort)
    end
  end
end
