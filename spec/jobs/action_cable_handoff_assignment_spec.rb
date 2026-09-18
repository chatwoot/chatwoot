require 'rails_helper'

RSpec.describe 'Assignment provenance through Action Cable', type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account, assignee: agent).reload }
  let(:event) { Events::Base.new(Events::Types::ASSIGNEE_CHANGED, Time.current, conversation: conversation, performed_by: inbox) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    conversation
    clear_enqueued_jobs
    allow(ActionCable.server).to receive(:broadcast)
  end

  after { Current.reset }

  it 'delivers automatic assignment provenance even inside a human-authenticated request' do
    Current.user = agent
    perform_enqueued_jobs(only: ActionCableBroadcastJob) { ActionCableListener.instance.assignee_changed(event) }

    expect(ActionCable.server).to have_received(:broadcast).with(
      agent.pubsub_token,
      hash_including(
        event: Events::Types::ASSIGNEE_CHANGED,
        data: hash_including(assignment: {
                               automatic: true, assignee_id: agent.id, assignee_type: 'User', updated_at: conversation.updated_at.to_f
                             })
      )
    )
  end

  it 'marks automation rule assignments automatic' do
    conversation.update!(assignee: nil)
    rule = create(:automation_rule, account: account, actions: [{ action_name: 'assign_agent', action_params: [agent.id] }])
    clear_enqueued_jobs
    Current.user = agent

    perform_enqueued_jobs(only: ActionCableBroadcastJob) { AutomationRules::ActionService.new(rule, account, conversation).perform }

    expect(ActionCable.server).to have_received(:broadcast).with(
      agent.pubsub_token,
      hash_including(
        event: Events::Types::ASSIGNEE_CHANGED,
        data: hash_including(assignment: hash_including(automatic: true, assignee_id: agent.id, assignee_type: 'User'))
      )
    )
  end

  it 'does not mark a manual assignment automatic' do
    Current.user = agent
    event.data[:performed_by] = nil
    perform_enqueued_jobs(only: ActionCableBroadcastJob) { ActionCableListener.instance.assignee_changed(event) }

    expect(ActionCable.server).to have_received(:broadcast).with(
      agent.pubsub_token,
      hash_including(data: hash_including(assignment: hash_including(automatic: false, assignee_id: agent.id)))
    )
  end

  it 'does not infer automatic assignment from missing actor information' do
    Current.user = nil
    event.data[:performed_by] = nil
    perform_enqueued_jobs(only: ActionCableBroadcastJob) { ActionCableListener.instance.assignee_changed(event) }

    expect(ActionCable.server).to have_received(:broadcast).with(
      agent.pubsub_token,
      hash_including(data: hash_including(assignment: hash_including(automatic: false)))
    )
  end

  it 'keeps the original assignment identity when the conversation is refreshed to a different owner' do
    ActionCableListener.instance.assignee_changed(event)
    queued_assignment = enqueued_jobs.find { |job| job[:job] == ActionCableBroadcastJob }
    replacement = create(:user, account: account)
    conversation.update!(assignee: replacement)
    clear_enqueued_jobs

    ActiveJob::Base.execute(queued_assignment)

    expect(ActionCable.server).to have_received(:broadcast).with(
      agent.pubsub_token,
      hash_including(data: hash_including(
        meta: hash_including(assignee: hash_including(id: replacement.id)),
        assignment: hash_including(automatic: true, assignee_id: agent.id, assignee_type: 'User')
      ))
    )
  end

  it 'does not mark an assignment queued before the metadata contract automatic' do
    ActionCableBroadcastJob.perform_now(
      [agent.pubsub_token], Events::Types::ASSIGNEE_CHANGED,
      conversation.push_event_data.merge(account_id: account.id)
    )

    expect(ActionCable.server).to have_received(:broadcast).with(
      agent.pubsub_token,
      hash_including(data: hash_including(assignment: hash_including(automatic: false)))
    )
  end
end
