require 'rails_helper'

RSpec.describe ActionCableBroadcastJob do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:members) { ['agent-token'] }
  let(:base_data) { { id: conversation.display_id, account_id: account.id } }

  describe '#perform' do
    context 'when the event is a conversation update' do
      let(:event_name) { 'conversation.updated' }
      let(:data) { base_data.merge(event_metadata: { source: 'reaction_toggle' }) }

      # The job re-fetches `conversation.push_event_data` to drop stale
      # snapshots in race conditions, but transient per-event tags (eg. the
      # `reaction_toggle` source the frontend reads to skip auto-scroll) live
      # only on the original payload — they have to be carried forward.
      it 'preserves event_metadata after refreshing the payload' do
        expect(ActionCable.server).to receive(:broadcast) do |_member, payload|
          expect(payload[:event]).to eq('conversation.updated')
          expect(payload[:data][:event_metadata]).to eq(source: 'reaction_toggle')
          # And the refresh still happened — id comes from the reloaded record.
          expect(payload[:data][:id]).to eq(conversation.display_id)
        end
        described_class.new.perform(members, event_name, data)
      end
    end

    context 'when the event is a conversation update without event_metadata' do
      let(:event_name) { 'conversation.updated' }
      let(:data) { base_data }

      # Regression guard: a missing `event_metadata` must NOT be assigned as `nil`
      # on the refreshed payload. The frontend uses optional chaining today, but
      # locking the absence here protects against a future loosening of the
      # `present?` check on the job side.
      it 'does not inject a nil event_metadata key' do
        expect(ActionCable.server).to receive(:broadcast) do |_member, payload|
          expect(payload[:event]).to eq('conversation.updated')
          expect(payload[:data]).not_to have_key(:event_metadata)
          expect(payload[:data][:id]).to eq(conversation.display_id)
        end
        described_class.new.perform(members, event_name, data)
      end
    end

    # The refresh rebuilds the payload from the conversation row, so it is the
    # one place that can silently undo the narrowing done by
    # ActionCableListener#broadcast_to_contact and hand the contact's browser the
    # full agent payload. The rule it encodes: refresh the values, preserve the
    # shape. That keeps this job from having to know which keys are agent-only —
    # including the ones Pro and Enterprise add to `push_data`.
    context 'when a contact-bound payload arrives narrowed to the allowlist' do
      let(:event_name) { 'conversation.updated' }
      let(:data) do
        Conversations::EventDataPresenter.contact_slice(conversation.push_event_data)
                                         .merge(account_id: account.id)
      end

      before do
        create(:message, conversation: conversation, account: account,
                         message_type: :outgoing, private: true, content: 'Internal only: overdue invoice')
      end

      it 'does not widen it back to the agent payload' do
        expect(ActionCable.server).to receive(:broadcast) do |_member, payload|
          expect(payload[:data]).not_to have_key(:last_non_activity_message)
          expect(payload[:data]).not_to have_key(:labels)
          expect(payload[:data]).not_to have_key(:custom_attributes)
          # The refresh still ran — this is not a pass-through.
          expect(payload[:data][:status]).to eq(conversation.status)
        end
        described_class.new.perform(members, event_name, data)
      end
    end

    context 'when an agent-bound payload carries agent-only keys' do
      let(:event_name) { 'conversation.updated' }
      let(:data) do
        conversation.push_event_data.merge(account_id: account.id,
                                           last_non_activity_message: { id: 0, content: 'stale snapshot' })
      end

      before do
        create(:message, conversation: conversation, account: account,
                         message_type: :outgoing, private: true, content: 'Internal only: overdue invoice')
      end

      it 'refreshes them instead of dropping them' do
        expect(ActionCable.server).to receive(:broadcast) do |_member, payload|
          expect(payload[:data][:last_non_activity_message][:content]).to eq('Internal only: overdue invoice')
        end
        described_class.new.perform(members, event_name, data)
      end
    end

    context 'when the event is not in the refresh list' do
      let(:event_name) { 'message.created' }
      let(:data) { base_data.merge(event_metadata: { source: 'reaction_toggle' }) }

      it 'broadcasts the original data verbatim' do
        expect(ActionCable.server).to receive(:broadcast) do |member, payload|
          expect(member).to eq('agent-token')
          expect(payload[:event]).to eq('message.created')
          expect(payload[:data]).to eq(data)
        end
        described_class.new.perform(members, event_name, data)
      end
    end
  end

  describe 'widget sessions' do
    let(:stale_data) { { id: conversation.display_id, account_id: account.id, status: 'open' } }
    # Agents are handed the whole conversation, and the refresh keeps the keys it was handed.
    let(:stale_agent_data) { conversation.push_event_data.merge(account_id: account.id, status: 'open') }

    before do
      conversation.update!(status: :resolved)
      allow(ActionCable.server).to receive(:broadcast)
    end

    it 'refreshes a conversation event with the full payload for agents and the widget payload for widget sessions' do
      described_class.perform_now(['agent-token'], Events::Types::CONVERSATION_STATUS_CHANGED, stale_agent_data,
                                  widget_members: ['widget-token'], widget_data: stale_data)

      expect(ActionCable.server).to have_received(:broadcast).with(
        'agent-token',
        { event: Events::Types::CONVERSATION_STATUS_CHANGED, data: conversation.reload.push_event_data.merge(account_id: account.id) }
      )
      expect(ActionCable.server).to have_received(:broadcast).with(
        'widget-token',
        { event: Events::Types::CONVERSATION_STATUS_CHANGED, data: conversation.reload.widget_push_event_data.merge(account_id: account.id) }
      )
    end

    it 'sends the prebuilt payloads for events that are not refreshed' do
      widget_data = { id: 1, account_id: account.id }
      described_class.perform_now(['agent-token'], Events::Types::MESSAGE_CREATED, { id: 1, content: 'hi', account_id: account.id },
                                  widget_members: ['widget-token'], widget_data: widget_data)

      expect(ActionCable.server).to have_received(:broadcast).with(
        'agent-token', { event: Events::Types::MESSAGE_CREATED, data: { id: 1, content: 'hi', account_id: account.id } }
      )
      expect(ActionCable.server).to have_received(:broadcast).with(
        'widget-token', { event: Events::Types::MESSAGE_CREATED, data: widget_data }
      )
    end

    it 'sends widget sessions their payload when there are no agent members' do
      described_class.perform_now([], Events::Types::CONVERSATION_STATUS_CHANGED, stale_data,
                                  widget_members: ['widget-token'], widget_data: stale_data)

      expect(ActionCable.server).to have_received(:broadcast).once.with(
        'widget-token',
        { event: Events::Types::CONVERSATION_STATUS_CHANGED, data: conversation.reload.widget_push_event_data.merge(account_id: account.id) }
      )
    end
  end
end
