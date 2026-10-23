require 'rails_helper'

RSpec.describe Conversations::UserMentionJob do
  let(:conversation) { create(:conversation) }
  let(:account) { conversation.account }
  let(:agents) { create_list(:user, 2, account: account) }

  it 'creates the mentions and dispatches one membership changed event' do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)

    described_class.perform_now(agents.map(&:id), conversation.id, account.id)

    expect(conversation.mentions.pluck(:user_id)).to match_array(agents.map(&:id))
    expect(Rails.configuration.dispatcher).to have_received(:dispatch)
      .with(Events::Types::CONVERSATION_MEMBERSHIP_CHANGED, anything, conversation: conversation).once
  end
end
