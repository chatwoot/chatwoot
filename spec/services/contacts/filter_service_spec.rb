require 'rails_helper'

describe ::Contacts::FilterService do
  subject(:filter_service) { described_class }

  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:en_contact) { create(:contact, account: account, additional_attributes: { 'browser_language': 'en' }) }
  let(:el_contact) { create(:contact, account: account, additional_attributes: { 'browser_language': 'el' }) }
  let(:cs_contact) { create(:contact, account: account, additional_attributes: { 'browser_language': 'cs' }) }

  before do
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, assignee: user_1, contact: en_contact)
    create(:conversation, account: account, inbox: inbox)
    Current.account = account

    create(:custom_attribute_definition,
           attribute_key: 'contact_additional_information',
           account: account,
           attribute_model: 'contact_attribute',
           attribute_display_type: 'text')
    create(:custom_attribute_definition,
           attribute_key: 'customer_type',
           account: account,
           attribute_model: 'contact_attribute',
           attribute_display_type: 'list',
           attribute_values: %w[regular platinum gold])
    create(:custom_attribute_definition,
           attribute_key: 'signed_in_at',
           account: account,
           attribute_model: 'contact_attribute',
           attribute_display_type: 'date')
  end

  describe '#perform' do
    before do
      en_contact.add_labels(%w[random_label support])
      el_contact.update_labels('random_label')
      cs_contact.update_labels('support')

      en_contact.update!(custom_attributes: { contact_additional_information: 'test custom data' })
      el_contact.update!(custom_attributes: { contact_additional_information: 'test custom data', customer_type: 'platinum' })
      cs_contact.update!(custom_attributes: { customer_type: 'platinum', signed_in_at: '2022-01-19' })
    end

    context 'with query present' do
      let!(:params) { { payload: [], page: 1 } }
      let(:payload) do
        [
          {
            attribute_key: 'browser_language',
            filter_operator: 'equal_to',
            values: ['en'],
            query_operator: 'OR'
          }.with_indifferent_access,
          {
            attribute_key: 'name',
            filter_operator: 'equal_to',
            values: [en_contact.name],
            query_operator: nil
          }.with_indifferent_access
        ]
      end

      it 'filter contacts by additional_attributes' do
        params[:payload] = payload
        result = filter_service.new(params, user_1).perform
        expect(result[:count]).to be 2
      end

      it 'filter contact by tags' do
        label_id = cs_contact.labels.last.id
        params[:payload] = [
          {
            attribute_key: 'labels',
            filter_operator: 'equal_to',
            values: [label_id],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(params, user_1).perform
        expect(result[:contacts].length).to be 2
        expect(result[:contacts].first.label_list).to include('support')
        expect(result[:contacts].last.label_list).to include('support')
      end

      it 'filter by custom_attributes and labels' do
        label_id = cs_contact.labels.last.id
        params[:payload] = [
          {
            attribute_key: 'customer_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'labels',
            filter_operator: 'equal_to',
            values: [label_id],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'signed_in_at',
            filter_operator: 'is_less_than',
            values: ['2022-01-20'],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result[:contacts].length).to be 1
        expect(result[:contacts].first.id).to eq(cs_contact.id)
      end

      it 'filter by custom_attributes and additional_attributes' do
        params[:payload] = [
          {
            attribute_key: 'customer_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'browser_language',
            filter_operator: 'equal_to',
            values: ['el'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'contact_additional_information',
            filter_operator: 'equal_to',
            values: ['test custom data'],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result[:contacts].length).to be 1
        expect(result[:contacts].first.id).to eq(el_contact.id)
      end

      it 'filter by created_at and custom_attributes' do
        tomorrow = Date.tomorrow.strftime
        params[:payload] = [
          {
            attribute_key: 'customer_type',
            filter_operator: 'equal_to',
            values: ['platinum'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'created_at',
            filter_operator: 'is_less_than',
            values: [tomorrow.to_s],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expected_count = Contact.where("created_at < ? AND custom_attributes->>'customer_type' = ?", Date.tomorrow, 'platinum').count

        expect(result[:contacts].length).to be expected_count
        expect(result[:contacts].pluck(:id)).to include(el_contact.id)
      end

      context 'with x_days_before filter' do
        before do
          el_contact.update(last_activity_at: (Time.zone.today - 4.days))
          cs_contact.update(last_activity_at: (Time.zone.today - 5.days))
          en_contact.update(last_activity_at: (Time.zone.today - 2.days))
        end

        it 'filter by last_activity_at 3_days_before and custom_attributes' do
          params[:payload] = [
            {
              attribute_key: 'last_activity_at',
              filter_operator: 'days_before',
              values: [3],
              query_operator: 'AND'
            }.with_indifferent_access,
            {
              attribute_key: 'contact_additional_information',
              filter_operator: 'equal_to',
              values: ['test custom data'],
              query_operator: nil
            }.with_indifferent_access
          ]

          expected_count = Contact.where(
            "last_activity_at < ? AND
            custom_attributes->>'contact_additional_information' = ?",
            (Time.zone.today - 3.days),
            'test custom data'
          ).count

          result = filter_service.new(params, user_1).perform
          expect(result[:contacts].length).to be expected_count
          expect(result[:contacts].first.id).to eq(el_contact.id)
        end

        it 'filter by last_activity_at 2_days_before and custom_attributes' do
          params[:payload] = [
            {
              attribute_key: 'last_activity_at',
              filter_operator: 'days_before',
              values: [2],
              query_operator: nil
            }.with_indifferent_access
          ]

          expected_count = Contact.where('last_activity_at < ?', (Time.zone.today - 2.days)).count

          result = filter_service.new(params, user_1).perform
          expect(result[:contacts].length).to be expected_count
          expect(result[:contacts].pluck(:id)).to include(el_contact.id)
          expect(result[:contacts].pluck(:id)).to include(cs_contact.id)
          expect(result[:contacts].pluck(:id)).not_to include(en_contact.id)
        end
      end
    end
  end
end
