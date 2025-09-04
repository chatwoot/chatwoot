require 'rails_helper'

RSpec.describe AutoAssignment::AssignmentService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: true) }
  let(:service) { described_class.new(inbox: inbox) }
  let(:agent) { create(:user, account: account, role: :agent, availability: :online) }
  let(:agent2) { create(:user, account: account, role: :agent, availability: :online) }
  let(:conversation) { create(:conversation, inbox: inbox, assignee: nil) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
  end

  describe '#perform_bulk_assignment' do
    context 'when auto assignment is enabled' do
      before do
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agent.id.to_s => 'online' })
      end

      it 'assigns conversations to available agents' do
        assigned_count = service.perform_bulk_assignment(limit: 1)

        expect(assigned_count).to eq(1)
        expect(conversation.reload.assignee).to eq(agent)
      end

      it 'returns 0 when no agents are online' do
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({})

        assigned_count = service.perform_bulk_assignment(limit: 1)

        expect(assigned_count).to eq(0)
        expect(conversation.reload.assignee).to be_nil
      end

      it 'respects the limit parameter' do
        3.times { create(:conversation, inbox: inbox, assignee: nil) }

        assigned_count = service.perform_bulk_assignment(limit: 2)

        expect(assigned_count).to eq(2)
        expect(inbox.conversations.unassigned.count).to eq(1)
      end

      it 'only assigns open conversations' do
        resolved_conversation = create(:conversation, inbox: inbox, assignee: nil, status: 'resolved')

        assigned_count = service.perform_bulk_assignment(limit: 10)

        expect(conversation.reload.assignee).to eq(agent)
        expect(resolved_conversation.reload.assignee).to be_nil
      end

      it 'does not reassign already assigned conversations' do
        assigned_conversation = create(:conversation, inbox: inbox, assignee: agent)
        unassigned_conversation = create(:conversation, inbox: inbox, assignee: nil)

        assigned_count = service.perform_bulk_assignment(limit: 10)

        expect(assigned_count).to eq(2) # Original conversation + unassigned_conversation
        expect(assigned_conversation.reload.assignee).to eq(agent)
      end

      it 'dispatches assignee changed event' do
        expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
          Events::Types::ASSIGNEE_CHANGED,
          anything,
          hash_including(conversation: conversation, user: agent)
        )

        service.perform_bulk_assignment(limit: 1)
      end
    end

    context 'when auto assignment is disabled' do
      before { inbox.update!(enable_auto_assignment: false) }

      it 'returns 0 without processing' do
        assigned_count = service.perform_bulk_assignment(limit: 10)

        expect(assigned_count).to eq(0)
        expect(conversation.reload.assignee).to be_nil
      end
    end

    context 'with conversation priority' do
      before do
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({ agent.id.to_s => 'online' })
      end

      context 'when priority is longest_waiting' do
        before do
          allow(inbox).to receive(:auto_assignment_config).and_return({ 'conversation_priority' => 'longest_waiting' })
        end

        it 'assigns conversations with oldest last_activity_at first' do
          old_conversation = create(:conversation, 
                                   inbox: inbox, 
                                   assignee: nil, 
                                   created_at: 2.hours.ago,
                                   last_activity_at: 2.hours.ago)
          new_conversation = create(:conversation, 
                                   inbox: inbox, 
                                   assignee: nil,
                                   created_at: 1.hour.ago,
                                   last_activity_at: 1.hour.ago)

          service.perform_bulk_assignment(limit: 1)

          expect(old_conversation.reload.assignee).to eq(agent)
          expect(new_conversation.reload.assignee).to be_nil
        end
      end

      context 'when priority is default' do
        it 'assigns conversations by created_at' do
          old_conversation = create(:conversation, inbox: inbox, assignee: nil, created_at: 2.hours.ago)
          new_conversation = create(:conversation, inbox: inbox, assignee: nil, created_at: 1.hour.ago)

          service.perform_bulk_assignment(limit: 1)

          expect(old_conversation.reload.assignee).to eq(agent)
          expect(new_conversation.reload.assignee).to be_nil
        end
      end
    end

    context 'with fair distribution' do
      before do
        create(:inbox_member, inbox: inbox, user: agent2)
        allow(OnlineStatusTracker).to receive(:get_available_users).and_return({
          agent.id.to_s => 'online',
          agent2.id.to_s => 'online'
        })
      end

      context 'when fair distribution is enabled' do
        before do
          allow(inbox).to receive(:auto_assignment_config).and_return({
            'fair_distribution_limit' => 2,
            'fair_distribution_window' => 3600
          })
        end

        it 'respects the assignment limit per agent' do
          # Mock agent1 at limit
          allow_any_instance_of(AutoAssignment::RateLimiter).to receive(:within_limit?) do |limiter|
            limiter.agent == agent ? false : true
          end

          unassigned_conversation = create(:conversation, inbox: inbox, assignee: nil)

          service.perform_bulk_assignment(limit: 1)

          expect(unassigned_conversation.reload.assignee).to eq(agent2)
        end

        it 'tracks assignments in Redis' do
          rate_limiter = instance_double(AutoAssignment::RateLimiter, within_limit?: true)
          allow(AutoAssignment::RateLimiter).to receive(:new).and_return(rate_limiter)

          expect(rate_limiter).to receive(:track_assignment).with(conversation)

          service.perform_bulk_assignment(limit: 1)
        end

        it 'allows assignments after window expires' do
          # Simulate time passing for rate limit window
          Timecop.freeze(Time.current) do
            2.times do
              convo = create(:conversation, inbox: inbox, assignee: nil)
              service.perform_bulk_assignment(limit: 1)
              expect(convo.reload.assignee).not_to be_nil
            end
          end

          # Move forward past the window
          Timecop.freeze(Time.current + 2.hours) do
            new_convo = create(:conversation, inbox: inbox, assignee: nil)
            service.perform_bulk_assignment(limit: 1)
            expect(new_convo.reload.assignee).not_to be_nil
          end
        end
      end

      context 'when fair distribution is disabled' do
        it 'assigns without rate limiting' do
          5.times { create(:conversation, inbox: inbox, assignee: nil) }

          expect(AutoAssignment::RateLimiter).not_to receive(:new)

          assigned_count = service.perform_bulk_assignment(limit: 5)
          expect(assigned_count).to eq(5)
        end
      end

      context 'with round robin assignment' do
        it 'distributes conversations evenly among agents' do
          conversations = 4.times.map { create(:conversation, inbox: inbox, assignee: nil) }

          service.perform_bulk_assignment(limit: 4)

          agent1_count = conversations.count { |c| c.reload.assignee == agent }
          agent2_count = conversations.count { |c| c.reload.assignee == agent2 }

          # Should be distributed evenly (2 each) or close to even (3 and 1)
          expect([agent1_count, agent2_count].sort).to eq([2, 2]).or(eq([1, 3]))
        end
      end
    end
  end
end