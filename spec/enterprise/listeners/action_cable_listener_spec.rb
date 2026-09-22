require 'rails_helper'

describe ActionCableListener do
  describe '#copilot_message_created' do
    let(:event_name) { :copilot_message_created }
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user, assistant: assistant) }
    let(:copilot_message) { create(:captain_copilot_message, copilot_thread: copilot_thread) }
    let(:event) { Events::Base.new(event_name, Time.zone.now, copilot_message: copilot_message) }
    let(:listener) { described_class.instance }

    it 'broadcasts message to the user' do
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [user.pubsub_token],
        'copilot.message.created',
        copilot_message.push_event_data.merge(account_id: account.id)
      )

      listener.copilot_message_created(event)
    end
  end

  describe '#copilot_run_updated' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:thread) { create(:captain_copilot_thread, account: account, user: user, engine: :v2, assistant: nil) }
    let(:message) { create(:captain_copilot_message, copilot_thread: thread) }
    let(:run) { thread.copilot_runs.create!(triggering_message: message) }

    it 'broadcasts progress only to the owning user token' do
      event = Events::Base.new(:copilot_run_updated, Time.current, copilot_run: run)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [user.pubsub_token], 'copilot.run.updated', run.push_event_data.merge(account_id: account.id)
      )
      described_class.instance.copilot_run_updated(event)
    end
  end
end
