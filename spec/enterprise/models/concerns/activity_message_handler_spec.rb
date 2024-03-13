require 'rails_helper'

RSpec.describe ActivityMessageHandler do
  describe 'SLA policy updates' do
    let!(:conversation) { create(:conversation) }
    let!(:sla_policy) { create(:sla_policy) }

    it 'generates an activity message when the SLA policy is updated' do
      conversation.update(sla_policy_id: sla_policy.id)

      perform_enqueued_jobs

      activity_message = conversation.messages.where(message_type: 'activity').last

      expect(activity_message).not_to be_nil
      expect(activity_message.message_type).to eq('activity')
      expect(activity_message.content).to include('added SLA policy')
    end

    it 'generates an activity message when the SLA policy is removed' do
      conversation.update(sla_policy_id: sla_policy.id)
      conversation.update(sla_policy_id: nil)

      perform_enqueued_jobs

      activity_message = conversation.messages.where(message_type: 'activity').last

      expect(activity_message).not_to be_nil
      expect(activity_message.message_type).to eq('activity')
      expect(activity_message.content).to include('removed SLA policy')
    end
  end
end
