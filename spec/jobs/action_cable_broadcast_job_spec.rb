require 'rails_helper'

RSpec.describe ActionCableBroadcastJob do
  include Events::Types

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:members) { %w[test_member_1 test_member_2] }
  let(:event_name) { 'test.event' }
  let(:data) { { account_id: account.id, id: conversation.display_id } }
  let(:timestamp) { Time.zone.now.to_f }

  describe '#perform' do
    context 'when members are blank' do
      it 'returns without broadcasting' do
        expect(ActionCable.server).not_to receive(:broadcast)
        described_class.perform_now([], event_name, data, timestamp)
      end
    end

    context 'when event is not a conversation update event' do
      it 'broadcasts original data to all members' do
        members.each do |member|
          expect(ActionCable.server).to receive(:broadcast).with(
            member,
            {
              event: event_name,
              data: data,
              event_timestamp: timestamp
            }
          )
        end

        described_class.perform_now(members, event_name, data, timestamp)
      end
    end

    context 'when event is a conversation update event' do
      let(:conversation_data) { conversation.push_event_data.merge(account_id: account.id) }
      let(:conversation_update_events) do
        [
          Events::Types::CONVERSATION_READ,
          Events::Types::CONVERSATION_UPDATED,
          Events::Types::TEAM_CHANGED,
          Events::Types::ASSIGNEE_CHANGED,
          Events::Types::CONVERSATION_STATUS_CHANGED
        ]
      end

      it 'refreshes and broadcasts latest conversation data for each update event' do
        conversation_update_events.each do |update_event|
          members.each do |member|
            expect(ActionCable.server).to receive(:broadcast).with(
              member,
              {
                event: update_event,
                data: conversation_data,
                event_timestamp: timestamp
              }
            )
          end

          described_class.perform_now(members, update_event, data, timestamp)
        end
      end

      context 'when conversation is not found' do
        let(:data) { { account_id: account.id, id: 0 } }

        it 'raises ActiveRecord::RecordNotFound' do
          expect do
            described_class.perform_now(
              members,
              Events::Types::CONVERSATION_UPDATED,
              data,
              timestamp
            )
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe 'queue' do
    it 'uses critical queue' do
      expect(described_class.queue_name).to eq('critical')
    end
  end

  describe 'timestamp handling' do
    it 'includes event_timestamp in broadcast data' do
      expect(ActionCable.server).to receive(:broadcast).with(
        members.first,
        hash_including(event_timestamp: timestamp)
      ).once

      expect(ActionCable.server).to receive(:broadcast).with(
        members.last,
        hash_including(event_timestamp: timestamp)
      ).once

      described_class.perform_now(members, event_name, data, timestamp)
    end
  end
end
