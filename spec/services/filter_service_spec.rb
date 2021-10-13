require 'rails_helper'

describe ::FilterService do
  subject(:filter_service) { described_class }

  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }

  before do
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, assignee: user_1)
    create(:conversation, account: account, inbox: inbox, assignee: user_1)
    create(:conversation, account: account, inbox: inbox, assignee: user_1, status: 'resolved')
    create(:conversation, account: account, inbox: inbox, assignee: user_2)
    # unassigned conversation
    create(:conversation, account: account, inbox: inbox)
    Current.account = account
  end

  describe '#perform' do
    context 'with query present' do
      let(:params) do
        [
          {
            attribute_key: 'browser_language',
            filter_operator: 'not_equal_to',
            values: ['en'],
            query_operator: 'AND',
          },
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['pending'],
            query_operator: nil,
          },
        ]
      end

      it 'filter conversations by custom_attributes and status' do
        result = filter_service.new('conversation', params, user_1).perform
        expect(result.length).to be 5
      end

      it 'filter contacts by custom_attributes and status' do
        result = filter_service.new('contact', params, user_1).perform
        expect(result.length).to be 5
      end
    end
  end
end
