## This spec is to ensure alignment between frontend and backend filters
# ref: https://github.com/chatwoot/chatwoot/pull/11111

require 'rails_helper'

describe Conversations::FilterService do
  describe 'Frontend alignment tests' do
    let!(:account) { create(:account) }
    let!(:user_1) { create(:user, account: account, role: :administrator) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:params) { { payload: [], page: 1 } }

    before do
      account.conversations.destroy_all

      # Create inbox membership
      create(:inbox_member, user: user_1, inbox: inbox)

      # Create custom attribute definition for conversation_type
      create(:custom_attribute_definition,
             attribute_key: 'conversation_type',
             account: account,
             attribute_model: 'conversation_attribute',
             attribute_display_type: 'list',
             attribute_values: %w[platinum silver gold regular])
    end

    context 'with A AND B OR C filter chain' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user_1) }
      let(:filter_payload) do
        [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['open'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'priority',
            filter_operator: 'equal_to',
            values: ['urgent'],
            query_operator: 'OR'
          }.with_indifferent_access,
          {
            attribute_key: 'display_id',
            filter_operator: 'equal_to',
            values: ['12345'],
            query_operator: nil
          }.with_indifferent_access
        ]
      end

      before do
        conversation.update!(
          status: 'open',
          priority: 'urgent',
          display_id: '12345',
          additional_attributes: { 'browser_language': 'en' }
        )
      end

      it 'matches when all conditions are true' do
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end

      it 'matches when first condition is false but third is true' do
        conversation.update!(status: 'resolved', priority: 'urgent', display_id: '12345')
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end

      it 'matches when first and second condition is false but third is true' do
        conversation.update!(status: 'resolved', priority: 'low', display_id: '12345')
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end

      it 'does not match when all conditions are false' do
        conversation.update!(status: 'resolved', priority: 'low', display_id: '67890')
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 0
      end
    end

    context 'with A OR B AND C filter chain' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user_1) }
      let(:filter_payload) do
        [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['open'],
            query_operator: 'OR'
          }.with_indifferent_access,
          {
            attribute_key: 'priority',
            filter_operator: 'equal_to',
            values: ['low'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'display_id',
            filter_operator: 'equal_to',
            values: ['67890'],
            query_operator: nil
          }.with_indifferent_access
        ]
      end

      before do
        conversation.update!(
          status: 'open',
          priority: 'urgent',
          display_id: '12345',
          additional_attributes: { 'browser_language': 'en' }
        )
      end

      it 'matches when first condition is true' do
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end

      it 'matches when second and third conditions are true' do
        conversation.update!(status: 'resolved', priority: 'low', display_id: '67890')
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end
    end

    context 'with complex filter chain A AND B OR C AND D' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user_1) }
      let(:filter_payload) do
        [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['open'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'priority',
            filter_operator: 'equal_to',
            values: ['urgent'],
            query_operator: 'OR'
          }.with_indifferent_access,
          {
            attribute_key: 'display_id',
            filter_operator: 'equal_to',
            values: ['67890'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'browser_language',
            filter_operator: 'equal_to',
            values: ['tr'],
            query_operator: nil
          }.with_indifferent_access
        ]
      end

      before do
        conversation.update!(
          status: 'open',
          priority: 'urgent',
          display_id: '12345',
          additional_attributes: { 'browser_language': 'en' },
          custom_attributes: { conversation_type: 'platinum' }
        )
      end

      it 'matches when first two conditions are true' do
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end

      it 'matches when last two conditions are true' do
        conversation.update!(
          status: 'resolved',
          priority: 'low',
          display_id: '67890',
          additional_attributes: { 'browser_language': 'tr' }
        )
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end
    end

    context 'with mixed operators filter chain' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user_1) }
      let(:filter_payload) do
        [
          {
            attribute_key: 'status',
            filter_operator: 'equal_to',
            values: ['open'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'priority',
            filter_operator: 'equal_to',
            values: ['urgent'],
            query_operator: 'OR'
          }.with_indifferent_access,
          {
            attribute_key: 'display_id',
            filter_operator: 'equal_to',
            values: ['67890'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'conversation_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            custom_attribute_type: '',
            query_operator: nil
          }.with_indifferent_access
        ]
      end

      before do
        conversation.update!(
          status: 'open',
          priority: 'urgent',
          display_id: '12345',
          additional_attributes: { 'browser_language': 'en' },
          custom_attributes: { conversation_type: 'platinum' }
        )
      end

      it 'matches when all conditions in the chain are true' do
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end

      it 'does not match when the last condition is false' do
        conversation.update!(custom_attributes: { conversation_type: 'silver' })
        params[:payload] = filter_payload
        result = described_class.new(params, user_1, account).perform
        expect(result[:conversations].length).to be 1
      end
    end
  end
end
