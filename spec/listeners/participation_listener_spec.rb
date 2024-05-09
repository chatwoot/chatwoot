require 'rails_helper'
describe ParticipationListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    Current.user = nil
    Current.account = nil
  end

  describe '#assignee_changed' do
    let(:event_name) { :assignee_changed }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }

    it 'adds the assignee as a participant to the conversation' do
      expect(conversation.conversation_participants.map(&:user_id)).not_to include(admin.id)
      listener.assignee_changed(event)
      expect(conversation.conversation_participants.map(&:user_id)).to include(agent.id)
    end
  end
end
