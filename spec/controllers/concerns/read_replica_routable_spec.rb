require 'rails_helper'

RSpec.describe ReadReplicaRoutable do
  let(:routed_actions) do
    {
      Api::V1::Accounts::SearchController => {
        contacts: 10,
        conversations: 10
      },
      Api::V1::Accounts::ContactsController => {
        search: 10,
        show: 2
      },
      Api::V1::Accounts::ConversationsController => {
        index: 2,
        meta: 2,
        filter: 2,
        search: 10,
        show: 2
      },
      Api::V1::Accounts::Conversations::MessagesController => { index: 2 },
      Api::V1::Widget::ConversationsController => { index: 2 },
      Api::V1::Widget::MessagesController => { index: 2 },
      Api::V1::Widget::ContactsController => { show: 10 },
      Api::V1::Widget::CampaignsController => { index: 10 },
      Api::V1::Widget::InboxMembersController => { index: 10 },
      Public::Api::V1::Portals::ArticlesController => { index: 10 }
    }
  end

  it 'routes only the selected actions with their action-specific lag budgets' do
    routed_actions.each do |controller, expected_actions|
      actual_actions = controller.read_replica_action_config.transform_values { |config| config[:max_lag] }

      expect(actual_actions).to eq(expected_actions), controller.name
    end
  end

  it 'builds primary authorization context for conversation list and search actions' do
    expect(Api::V1::Accounts::SearchController.read_replica_action_config).to include(
      conversations: include(access_context: true)
    )
    expect(Api::V1::Accounts::ConversationsController.read_replica_action_config).to include(
      index: include(access_context: true),
      meta: include(access_context: true),
      filter: include(access_context: true),
      search: include(access_context: true)
    )
  end
end
