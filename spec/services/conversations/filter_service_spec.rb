require 'rails_helper'

describe Conversations::FilterService do
  subject(:filter_service) { described_class }

  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:campaign_1) { create(:campaign, title: 'Test Campaign', account: account) }
  let!(:campaign_2) { create(:campaign, title: 'Campaign', account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }

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
            filter_operator: 'equal_to',
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
        result = filter_service.new(params, user_1, account).perform
        conversations = Conversation.where("additional_attributes ->> 'browser_language' IN (?) AND status IN (?)", ['en'], [1, 2])
        expect(result[:count][:all_count]).to be conversations.count
      end

      it 'filter conversations by priority' do
        conversation = create(:conversation, account: account, inbox: inbox, assignee: user_1, priority: :high)
        params[:payload] = [
          {
            attribute_key: 'priority',
            filter_operator: 'equal_to',
            values: ['high'],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1, account).perform
        expect(result[:conversations].length).to eq 1
        expect(result[:conversations][0][:id]).to eq conversation.id
      end

      it 'filter conversations by multiple priority values' do
        high_priority = create(:conversation, account: account, inbox: inbox, assignee: user_1, priority: :high)
        urgent_priority = create(:conversation, account: account, inbox: inbox, assignee: user_1, priority: :urgent)
        create(:conversation, account: account, inbox: inbox, assignee: user_1, priority: :low)

        params[:payload] = [
          {
            attribute_key: 'priority',
            filter_operator: 'equal_to',
            values: %w[high urgent],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1, account).perform
        expect(result[:conversations].length).to eq 2
        expect(result[:conversations].pluck(:id)).to include(high_priority.id, urgent_priority.id)
      end

      it 'filter conversations with not_equal_to priority operator' do
        create(:conversation, account: account, inbox: inbox, assignee: user_1, priority: :high)
        create(:conversation, account: account, inbox: inbox, assignee: user_1, priority: :urgent)
        low_priority = create(:conversation, account: account, inbox: inbox, assignee: user_1, priority: :low)
        medium_priority = create(:conversation, account: account, inbox: inbox, assignee: user_1, priority: :medium)

        params[:payload] = [
          {
            attribute_key: 'priority',
            filter_operator: 'not_equal_to',
            values: %w[high urgent],
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1, account).perform

        # Only include conversations with medium and low priority, excluding high and urgent
        expect(result[:conversations].length).to eq 2
        expect(result[:conversations].pluck(:id)).to include(low_priority.id, medium_priority.id)
      end

      it 'filter conversations by additional_attributes and status with pagination' do
        params[:payload] = payload
        params[:page] = 2
        result = filter_service.new(params, user_1, account).perform
        conversations = Conversation.where("additional_attributes ->> 'browser_language' IN (?) AND status IN (?)", ['en'], [1, 2])
        expect(result[:count][:all_count]).to be conversations.count
      end

      it 'filters items with contains filter_operator with values being an array' do
        params[:payload] = [{
          attribute_key: 'browser_language',
          filter_operator: 'equal_to',
          values: %w[tr fr],
          query_operator: '',
          custom_attribute_type: ''
        }.with_indifferent_access]

        create(:conversation, account: account, inbox: inbox, assignee: user_1, campaign_id: campaign_1.id,
                              status: 'pending', additional_attributes: { 'browser_language': 'fr' })
        create(:conversation, account: account, inbox: inbox, assignee: user_1, campaign_id: campaign_1.id,
                              status: 'pending', additional_attributes: { 'browser_language': 'tr' })

        result = filter_service.new(params, user_1, account).perform
        expect(result[:count][:all_count]).to be 2
      end

      it 'filters items with does not contain filter operator with values being an array' do
        params[:payload] = [{
          attribute_key: 'browser_language',
          filter_operator: 'not_equal_to',
          values: %w[tr en],
          query_operator: '',
          custom_attribute_type: ''
        }.with_indifferent_access]

        create(:conversation, account: account, inbox: inbox, assignee: user_1, campaign_id: campaign_1.id,
                              status: 'pending', additional_attributes: { 'browser_language': 'fr' })
        create(:conversation, account: account, inbox: inbox, assignee: user_1, campaign_id: campaign_1.id,
                              status: 'pending', additional_attributes: { 'browser_language': 'tr' })

        result = filter_service.new(params, user_1, account).perform

        expect(result[:count][:all_count]).to be 1
        expect(result[:conversations].first.additional_attributes['browser_language']).to eq 'fr'
      end

      it 'filter conversations by additional_attributes with NOT_IN filter' do
        payload = [{ attribute_key: 'conversation_type', filter_operator: 'not_equal_to', values: 'platinum', query_operator: nil,
                     custom_attribute_type: 'conversation_attribute' }.with_indifferent_access]
        params[:payload] = payload
        result = filter_service.new(params, user_1, account).perform
        conversations = Conversation.where(
          "custom_attributes ->> 'conversation_type' NOT IN (?) OR custom_attributes ->> 'conversation_type' IS NULL", ['platinum']
        )
        expect(result[:count][:all_count]).to be conversations.count
      end

      it 'filter conversations by tags' do
        user_2_assigned_conversation.update_labels('support')
        params[:payload] = [
          {
            attribute_key: 'assignee_id',
            filter_operator: 'equal_to',
            values: [user_1.id, user_2.id],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'labels',
            filter_operator: 'equal_to',
            values: ['support'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'labels',
            filter_operator: 'not_equal_to',
            values: ['random-label'],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1, account).perform
        expect(result[:count][:all_count]).to be 1
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
        result = filter_service.new(params, user_1, account).perform

        expect(result[:count][:all_count]).to be 2
        expect(result[:conversations].pluck(:campaign_id).sort).to eq [campaign_2.id, campaign_1.id].sort
      end

      it 'handles invalid query conditions' do
        params[:payload] = [
          {
            attribute_key: 'assignee_id',
            filter_operator: 'equal_to',
            values: [
              user_1.id,
              user_2.id
            ],
            query_operator: 'INVALID',
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

        expect { filter_service.new(params, user_1, account).perform }.to raise_error(CustomExceptions::CustomFilter::InvalidQueryOperator)
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
        result = filter_service.new(params, user_1, account).perform
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
        result = filter_service.new(params, user_1, account).perform
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
        result = filter_service.new(params, user_1, account).perform
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
        result = filter_service.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end

      it 'filter by custom_attributes and additional_attributes' do
        conversations = user_1.conversations
        conversations[0].update!(additional_attributes: { 'browser_language': 'en' }, custom_attributes: { conversation_type: 'silver' })
        conversations[1].update!(additional_attributes: { 'browser_language': 'en' }, custom_attributes: { conversation_type: 'platinum' })
        conversations[2].update!(additional_attributes: { 'browser_language': 'tr' }, custom_attributes: { conversation_type: 'platinum' })

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
            filter_operator: 'not_equal_to',
            values: 'en',
            query_operator: nil,
            custom_attribute_type: ''
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1, account).perform
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
        result = filter_service.new(params, user_1, account).perform
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
        result = filter_service.new(params, user_1, account).perform
        expected_count = Conversation.where("created_at > ? AND custom_attributes->>'conversation_type' = ?", DateTime.parse('2022-01-20'),
                                            'platinum').count

        expect(result[:conversations].length).to be expected_count
      end

      context 'with x_days_before filter' do
        before do
          Time.zone = 'UTC'
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

          result = filter_service.new(params, user_1, account).perform
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

          result = filter_service.new(params, user_1, account).perform
          expect(result[:conversations].length).to be expected_count
        end
      end
    end
  end

  describe '#perform on date filter with no current account' do
    before do
      Current.account = nil
    end

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
        result = filter_service.new(params, user_1, account).perform
        expected_count = Conversation.where('created_at > ?', DateTime.parse('2022-01-20')).count

        expect(Current.account).to be_nil
        expect(result[:conversations].length).to be expected_count
      end
    end
  end

  describe '#base_relation' do
    let!(:account) { create(:account) }
    let!(:user_1) { create(:user, account: account, role: :agent) }
    let!(:admin) { create(:user, account: account, role: :administrator) }
    let!(:inbox_1) { create(:inbox, account: account) }
    let!(:inbox_2) { create(:inbox, account: account) }
    let!(:params) { { payload: [], page: 1 } }

    before do
      account.conversations.destroy_all

      # Make user_1 a regular agent with access to inbox_1 only
      create(:inbox_member, user: user_1, inbox: inbox_1)

      # Create conversations in both inboxes
      create(:conversation, account: account, inbox: inbox_1)
      create(:conversation, account: account, inbox: inbox_2)
    end

    it 'returns all conversations for administrators, even for inboxes they are not members of' do
      service = filter_service.new(params, admin, account)
      result = service.perform
      expect(result[:conversations].count).to eq 2
    end

    it 'filters conversations by inbox membership for non-administrators' do
      service = filter_service.new(params, user_1, account)
      result = service.perform
      expect(result[:conversations].count).to eq 1
    end
  end
end
