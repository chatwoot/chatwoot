require 'rails_helper'

describe ::Conversations::FilterService do
  subject(:filter_service) { described_class }

  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:campaign_1) { create(:campaign, title: 'Test Campaign', account: account) }
  let!(:campaign_2) { create(:campaign, title: 'Campaign', account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }

  let!(:unassigned_conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:user_2_assigned_conversation) { create(:conversation, account: account, inbox: inbox, assignee: user_2) }
  let!(:en_conversation_1) do
    create(:conversation, account: account, inbox: inbox, assignee: user_1, campaign_id: campaign_1.id,
                          status: 'pending', additional_attributes: { 'browser_language': 'en' })
  end
  let!(:en_conversation_2) do
    create(:conversation, account: account, inbox: inbox, assignee: user_1, campaign_id: campaign_2.id,
                          status: 'pending', additional_attributes: { 'browser_language': 'en' })
  end

  before do
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)
    Current.account = account

    en_conversation_1.update!(custom_attributes: { conversation_additional_information: 'test custom data' })
    en_conversation_2.update!(custom_attributes: { conversation_additional_information: 'test custom data', conversation_type: 'platinum' })
    user_2_assigned_conversation.update!(custom_attributes: { conversation_type: 'platinum', conversation_created: '2022-01-19' })
    create(:conversation, account: account, inbox: inbox, assignee: user_1)

    create(:custom_attribute_definition,
           attribute_key: 'conversation_type',
           account: account,
           attribute_model: 'conversation_attribute',
           attribute_display_type: 'list',
           attribute_values: %w[regular platinum gold])
    create(:custom_attribute_definition,
           attribute_key: 'conversation_created',
           account: account,
           attribute_model: 'conversation_attribute',
           attribute_display_type: 'date')
    create(:custom_attribute_definition,
           attribute_key: 'conversation_additional_information',
           account: account,
           attribute_model: 'conversation_attribute',
           attribute_display_type: 'text')
  end

  describe '#perform' do
    context 'with query present' do
      let!(:params) { { payload: [], page: 1 } }
      let(:payload) do
        [
          {
            attribute_key: 'browser_language',
            filter_operator: 'contains',
            values: 'en',
            query_operator: 'AND',
            custom_attribute_type: ''
          }.with_indifferent_access,
          {
            attribute_key: 'status',
            filter_operator: 'not_equal_to',
            values: %w[resolved],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
      end

      it 'filter conversations by additional_attributes and status' do
        params[:payload] = payload
        result = filter_service.new(params, user_1).perform
        conversations = Conversation.where("additional_attributes ->> 'browser_language' IN (?) AND status IN (?)", ['en'], [1, 2])
        expect(result.length).to be conversations.count
      end

      it 'filter conversations by additional_attributes and status with pagination' do
        params[:payload] = payload
        params[:page] = 2
        result = filter_service.new(params, user_1).perform
        conversations = Conversation.where("additional_attributes ->> 'browser_language' IN (?) AND status IN (?)", ['en'], [1, 2])
        expect(result.length).to be conversations.count
      end

      it 'filter conversations by tags' do
        unassigned_conversation.update_labels('support')
        params[:payload] = [
          {
            attribute_key: 'assignee_id',
            filter_operator: 'equal_to',
            values: [
              user_1.id,
              user_2.id
            ],
            query_operator: 'AND',
            custom_attribute_type: ''
          }.with_indifferent_access,
          {
            attribute_key: 'labels',
            filter_operator: 'equal_to',
            values: ['support'],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result.length).to be 2
      end

      it 'filter conversations by is_present filter_operator' do
        params[:payload] = [
          {
            attribute_key: 'assignee_id',
            filter_operator: 'equal_to',
            values: [
              user_1.id,
              user_2.id
            ],
            query_operator: 'AND',
            custom_attribute_type: ''
          }.with_indifferent_access,
          {
            attribute_key: 'campaign_id',
            filter_operator: 'is_present',
            values: [],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform

        expect(result[:count][:all_count]).to be 2
        expect(result[:conversations].pluck(:campaign_id).sort).to eq [campaign_2.id, campaign_1.id].sort
      end
    end
  end

  describe '#perform on custom attribute' do
    context 'with query present' do
      let!(:params) { { payload: [], page: 1 } }

      it 'filter by custom_attributes and labels' do
        user_2_assigned_conversation.update_labels('support')
        params[:payload] = [
          {
            attribute_key: 'conversation_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'conversation_created',
            filter_operator: 'is_less_than',
            values: ['2022-01-20'],
            query_operator: 'OR',
            custom_attribute_type: ''
          }.with_indifferent_access,
          {
            attribute_key: 'labels',
            filter_operator: 'equal_to',
            values: ['support'],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result[:conversations].length).to be 1
        expect(result[:conversations][0][:id]).to be user_2_assigned_conversation.id
      end

      it 'filter by custom_attributes and labels with custom_attribute_type nil' do
        user_2_assigned_conversation.update_labels('support')
        params[:payload] = [
          {
            attribute_key: 'conversation_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'conversation_created',
            filter_operator: 'is_less_than',
            values: ['2022-01-20'],
            query_operator: 'OR',
            custom_attribute_type: nil
          }.with_indifferent_access,
          {
            attribute_key: 'labels',
            filter_operator: 'equal_to',
            values: ['support'],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result[:conversations].length).to be 1
        expect(result[:conversations][0][:id]).to be user_2_assigned_conversation.id
      end

      it 'filter by custom_attributes' do
        params[:payload] = [
          {
            attribute_key: 'conversation_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND',
            custom_attribute_type: ''
          }.with_indifferent_access,
          {
            attribute_key: 'conversation_created',
            filter_operator: 'is_less_than',
            values: ['2022-01-20'],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result[:conversations].length).to be 1
      end

      it 'filter by custom_attributes with custom_attribute_type nil' do
        params[:payload] = [
          {
            attribute_key: 'conversation_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND',
            custom_attribute_type: nil
          }.with_indifferent_access,
          {
            attribute_key: 'conversation_created',
            filter_operator: 'is_less_than',
            values: ['2022-01-20'],
            query_operator: nil,
            custom_attribute_type: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result[:conversations].length).to be 1
      end

      it 'filter by custom_attributes and additional_attributes' do
        params[:payload] = [
          {
            attribute_key: 'conversation_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND',
            custom_attribute_type: ''
          }.with_indifferent_access,
          {
            attribute_key: 'browser_language',
            filter_operator: 'is_equal_to',
            values: 'en',
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result[:conversations].length).to be 1
      end
    end
  end

  describe '#perform on date filter' do
    context 'with query present' do
      let!(:params) { { payload: [], page: 1 } }

      it 'filter by created_at' do
        params[:payload] = [
          {
            attribute_key: 'created_at',
            filter_operator: 'is_greater_than',
            values: ['2022-01-20'],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expected_count = Conversation.where('created_at > ?', DateTime.parse('2022-01-20')).count
        expect(result[:conversations].length).to be expected_count
      end

      it 'filter by created_at and conversation_type' do
        params[:payload] = [
          {
            attribute_key: 'conversation_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND',
            custom_attribute_type: ''
          }.with_indifferent_access,
          {
            attribute_key: 'created_at',
            filter_operator: 'is_greater_than',
            values: ['2022-01-20'],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expected_count = Conversation.where("created_at > ? AND custom_attributes->>'conversation_type' = ?", DateTime.parse('2022-01-20'),
                                            'platinum').count

        expect(result[:conversations].length).to be expected_count
      end

      context 'with x_days_before filter' do
        before do
          en_conversation_1.update!(last_activity_at: (Time.zone.today - 4.days))
          en_conversation_2.update!(last_activity_at: (Time.zone.today - 5.days))
          user_2_assigned_conversation.update!(last_activity_at: (Time.zone.today - 2.days))
        end

        it 'filter by last_activity_at 3_days_before and custom_attributes' do
          params[:payload] = [
            {
              attribute_key: 'last_activity_at',
              filter_operator: 'days_before',
              values: [3],
              query_operator: 'AND',
              custom_attribute_type: ''
            }.with_indifferent_access,
            {
              attribute_key: 'conversation_type',
              filter_operator: 'equal_to',
              values: ['platinum'],
              query_operator: nil,
              custom_attribute_type: ''
            }.with_indifferent_access
          ]

          expected_count = Conversation.where("last_activity_at < ? AND custom_attributes->>'conversation_type' = ?", (Time.zone.today - 3.days),
                                              'platinum').count

          result = filter_service.new(params, user_1).perform
          expect(result[:conversations].length).to be expected_count
        end

        it 'filter by last_activity_at 2_days_before' do
          params[:payload] = [
            {
              attribute_key: 'last_activity_at',
              filter_operator: 'days_before',
              values: [3],
              query_operator: nil,
              custom_attribute_type: ''
            }.with_indifferent_access
          ]

          expected_count = Conversation.where('last_activity_at < ?', (Time.zone.today - 2.days)).count

          result = filter_service.new(params, user_1).perform
          expect(result[:conversations].length).to be expected_count
        end
      end
    end
  end
end
