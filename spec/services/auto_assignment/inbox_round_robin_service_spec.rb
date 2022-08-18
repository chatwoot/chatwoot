require 'rails_helper'

describe AutoAssignment::InboxRoundRobinService do
  subject(:inbox_round_robin_service) { described_class.new(inbox: inbox) }

  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:inbox_members) { create_list(:inbox_member, 5, inbox: inbox) }

  describe '#available_agent' do
    it 'returns nil if allowed_agent_ids is not passed or empty' do
      expect(described_class.new(inbox: inbox).available_agent).to be_nil
    end

    it 'gets the first available agent in allowed_agent_ids and move agent to end of the list' do
      expected_queue = [inbox_members[0].user_id, inbox_members[4].user_id, inbox_members[3].user_id, inbox_members[2].user_id,
                        inbox_members[1].user_id].map(&:to_s)
      described_class.new(inbox: inbox).available_agent(allowed_agent_ids: [inbox_members[0].user_id, inbox_members[4].user_id].map(&:to_s))
      expect(inbox_round_robin_service.send(:queue)).to eq(expected_queue)
    end

    it 'constructs round_robin_queue if queue is not present' do
      inbox_round_robin_service.clear_queue
      expect(inbox_round_robin_service.send(:queue)).to eq([])
      inbox_round_robin_service.available_agent
      # the service constructed the redis queue before performing
      expect(inbox_round_robin_service.send(:queue).sort.map(&:to_i)).to eq(inbox_members.map(&:user_id).sort)
    end

    it 'validates the queue and correct it before performing round robin' do
      # adding some invalid ids to queue
      inbox_round_robin_service.add_agent_to_queue([2, 3, 5, 9])
      expect(inbox_round_robin_service.send(:queue).sort.map(&:to_i)).not_to eq(inbox_members.map(&:user_id).sort)
      inbox_round_robin_service.available_agent
      # the service have refreshed the redis queue before performing
      expect(inbox_round_robin_service.send(:queue).sort.map(&:to_i)).to eq(inbox_members.map(&:user_id).sort)
    end

    context 'when allowed_agent_ids is passed' do
      it 'will get the first allowed member and move it to the end of the queue' do
        expected_queue = [inbox_members[3].user_id, inbox_members[2].user_id, inbox_members[4].user_id, inbox_members[1].user_id,
                          inbox_members[0].user_id].map(&:to_s)
        expect(described_class.new(inbox: inbox).available_agent(
                 allowed_agent_ids: [
                   inbox_members[3].user_id,
                   inbox_members[2].user_id
                 ].map(&:to_s)
               )).to eq inbox_members[2].user
        expect(described_class.new(inbox: inbox).available_agent(
                 allowed_agent_ids: [
                   inbox_members[3].user_id,
                   inbox_members[2].user_id
                 ].map(&:to_s)
               )).to eq inbox_members[3].user
        expect(inbox_round_robin_service.send(:queue)).to eq(expected_queue)
      end
    end
  end
end
