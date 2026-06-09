require 'rails_helper'

describe Contacts::FilterService do
  subject(:filter_service) { described_class }

  let!(:account) { create(:account) }
  let!(:first_user) { create(:user, account: account) }
  let!(:second_user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let!(:en_contact) do
    create(:contact,
           account: account,
           email: Faker::Internet.unique.email,
           additional_attributes: { 'country_code': 'uk' })
  end
  let!(:el_contact) do
    create(:contact,
           account: account,
           email: Faker::Internet.unique.email,
           additional_attributes: { 'country_code': 'gr' })
  end
  let!(:cs_contact) do
    create(:contact,
           :with_phone_number,
           account: account,
           email: Faker::Internet.unique.email,
           additional_attributes: { 'country_code': 'cz' })
  end

  before do
    create(:inbox_member, user: first_user, inbox: inbox)
    create(:inbox_member, user: second_user, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, assignee: first_user, contact: en_contact)
    create(:conversation, account: account, inbox: inbox, contact: el_contact)

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
    create(:custom_attribute_definition,
           attribute_key: 'lifetime_value',
           account: account,
           attribute_model: 'contact_attribute',
           attribute_display_type: 'number')
  end

  describe '#perform' do
    let!(:params) { { payload: [], page: 1 } }

    before do
      en_contact.update_labels(%w[random_label support])
      cs_contact.update_labels('support')

      en_contact.update!(custom_attributes: { contact_additional_information: 'test custom data' })
      el_contact.update!(custom_attributes: { contact_additional_information: 'test custom data', customer_type: 'platinum' })
      cs_contact.update!(custom_attributes: { customer_type: 'platinum', signed_in_at: '2022-01-19', lifetime_value: '120.50' })
    end

    context 'with standard attributes - name' do
      it 'filter contacts by name' do
        params[:payload] = [
          {
            attribute_key: 'name',
            filter_operator: 'equal_to',
            values: [en_contact.name],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(account, first_user, params).perform
        expect(result[:count]).to be 1
        expect(result[:contacts].length).to be 1
        expect(result[:contacts].first.name).to eq(en_contact.name)
      end
    end

    context 'with standard attributes - phone' do
      it 'filter contacts by name' do
        params[:payload] = [
          {
            attribute_key: 'phone_number',
            filter_operator: 'equal_to',
            values: [cs_contact.phone_number],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(account, first_user, params).perform
        expect(result[:count]).to be 1
        expect(result[:contacts].length).to be 1
        expect(result[:contacts].first.name).to eq(cs_contact.name)
      end
    end

    context 'with standard attributes - phone (without +)' do
      it 'filter contacts by name' do
        params[:payload] = [
          {
            attribute_key: 'phone_number',
            filter_operator: 'equal_to',
            values: [cs_contact.phone_number[1..]],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(account, first_user, params).perform
        expect(result[:count]).to be 1
        expect(result[:contacts].length).to be 1
        expect(result[:contacts].first.name).to eq(cs_contact.name)
      end
    end

    context 'with standard attributes - blocked' do
      it 'filter contacts by blocked' do
        blocked_contact = create(
          :contact,
          account: account,
          blocked: true,
          email: Faker::Internet.unique.email
        )
        params = { payload: [{ attribute_key: 'blocked', filter_operator: 'equal_to', values: ['true'],
                               query_operator: nil }.with_indifferent_access] }
        result = filter_service.new(account, first_user, params).perform
        expect(result[:count]).to be 1
        expect(result[:contacts].first.id).to eq(blocked_contact.id)
      end

      it 'filter contacts by not_blocked' do
        params = { payload: [{ attribute_key: 'blocked', filter_operator: 'equal_to', values: [false],
                               query_operator: nil }.with_indifferent_access] }
        result = filter_service.new(account, first_user, params).perform
        # existing contacts are not blocked
        expect(result[:count]).to be 3
      end
    end

    context 'with standard attributes - label' do
      it 'returns equal_to filter results properly' do
        params[:payload] = [
          {
            attribute_key: 'labels',
            filter_operator: 'equal_to',
            values: ['support'],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(account, first_user, params).perform
        expect(result[:contacts].length).to be 2
        expect(result[:contacts].first.label_list).to include('support')
        expect(result[:contacts].last.label_list).to include('support')
      end

      it 'returns not_equal_to filter results properly' do
        params[:payload] = [
          {
            attribute_key: 'labels',
            filter_operator: 'not_equal_to',
            values: ['support'],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(account, first_user, params).perform
        expect(result[:contacts].length).to be 1
        expect(result[:contacts].first.id).to eq el_contact.id
      end

      it 'returns is_present filter results properly' do
        params[:payload] = [
          {
            attribute_key: 'labels',
            filter_operator: 'is_present',
            values: [],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(account, first_user, params).perform
        expect(result[:contacts].length).to be 2
        expect(result[:contacts].first.label_list).to include('support')
        expect(result[:contacts].last.label_list).to include('support')
      end

      it 'returns is_not_present filter results properly' do
        params[:payload] = [
          {
            attribute_key: 'labels',
            filter_operator: 'is_not_present',
            values: [],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(account, first_user, params).perform
        expect(result[:contacts].length).to be 1
        expect(result[:contacts].first.id).to eq el_contact.id
      end

      it 'handles invalid query conditions' do
        params[:payload] = [
          {
            attribute_key: 'labels',
            filter_operator: 'is_not_present',
            values: [],
            query_operator: 'INVALID'
          }.with_indifferent_access
        ]

        expect { filter_service.new(account, first_user, params).perform }.to raise_error(CustomExceptions::CustomFilter::InvalidQueryOperator)
      end
    end

    context 'with standard attributes - last_activity_at' do
      before do
        Time.zone = 'UTC'
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

        result = filter_service.new(account, first_user, params).perform
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

        result = filter_service.new(account, first_user, params).perform
        expect(result[:contacts].length).to be expected_count
        expect(result[:contacts].pluck(:id)).to include(el_contact.id)
        expect(result[:contacts].pluck(:id)).to include(cs_contact.id)
        expect(result[:contacts].pluck(:id)).not_to include(en_contact.id)
      end

      it 'binds last_activity_at comparison values as dates' do
        date_value = '2024-01-01'
        params[:payload] = [
          {
            attribute_key: 'last_activity_at',
            filter_operator: 'is_greater_than',
            values: [date_value],
            query_operator: nil
          }.with_indifferent_access
        ]

        service = filter_service.new(account, first_user, params)
        filters = service.instance_variable_get(:@filters)['contacts']
        condition_query = service.send(:build_condition_query, filters, params[:payload].first, 0)

        expect(condition_query).to include('(contacts.last_activity_at)::date > :value_0')
        expect(service.instance_variable_get(:@filter_values)['value_0']).to eq(Date.iso8601(date_value))
      end

      it 'rejects invalid last_activity_at comparison values' do
        malicious_value = "2024-01-01'::date OR (SELECT pg_sleep(5)) IS NOT NULL --"
        params[:payload] = [
          {
            attribute_key: 'last_activity_at',
            filter_operator: 'is_greater_than',
            values: [malicious_value],
            query_operator: nil
          }.with_indifferent_access
        ]

        expect { filter_service.new(account, first_user, params).perform }.to raise_error(CustomExceptions::CustomFilter::InvalidValue)
      end
    end

    context 'with additional attributes' do
      let(:payload) do
        [
          {
            attribute_key: 'country_code',
            filter_operator: 'equal_to',
            values: ['uk'],
            query_operator: nil
          }.with_indifferent_access
        ]
      end

      it 'filter contacts by additional_attributes' do
        params[:payload] = payload
        result = filter_service.new(account, first_user, params).perform
        expect(result[:count]).to be 1
        expect(result[:contacts].first.id).to eq(en_contact.id)
      end
    end

    context 'with custom attributes' do
      it 'filter by custom_attributes and labels' do
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
            values: ['support'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'signed_in_at',
            filter_operator: 'is_less_than',
            values: ['2022-01-20'],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(account, first_user, params).perform
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
            attribute_key: 'country_code',
            filter_operator: 'equal_to',
            values: ['GR'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'contact_additional_information',
            filter_operator: 'equal_to',
            values: ['test custom data'],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(account, first_user, params).perform
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
        result = filter_service.new(account, first_user, params).perform
        expected_count = Contact.where("created_at < ? AND custom_attributes->>'customer_type' = ?", Date.tomorrow, 'platinum').count

        expect(result[:contacts].length).to be expected_count
        expect(result[:contacts].pluck(:id)).to include(el_contact.id)
      end

      it 'binds custom date comparison values as dates' do
        date_value = '2024-01-01'
        params[:payload] = [
          {
            attribute_key: 'signed_in_at',
            filter_operator: 'is_less_than',
            values: [date_value],
            query_operator: nil
          }.with_indifferent_access
        ]

        service = filter_service.new(account, first_user, params)
        filters = service.instance_variable_get(:@filters)['contacts']
        condition_query = service.send(:build_condition_query, filters, params[:payload].first, 0)

        expect(condition_query).to include("(contacts.custom_attributes ->> 'signed_in_at')::date < :value_0")
        expect(service.instance_variable_get(:@filter_values)['value_0']).to eq(Date.iso8601(date_value))
      end

      it 'binds custom numeric comparison values as decimals' do
        params[:payload] = [
          {
            attribute_key: 'lifetime_value',
            filter_operator: 'is_greater_than',
            values: ['100.25'],
            query_operator: nil
          }.with_indifferent_access
        ]

        service = filter_service.new(account, first_user, params)
        filters = service.instance_variable_get(:@filters)['contacts']
        condition_query = service.send(:build_condition_query, filters, params[:payload].first, 0)

        expect(condition_query).to include("(contacts.custom_attributes ->> 'lifetime_value')::numeric > :value_0")
        expect(service.instance_variable_get(:@filter_values)['value_0']).to eq(BigDecimal('100.25'))
      end

      it 'filters by custom numeric attributes' do
        params[:payload] = [
          {
            attribute_key: 'lifetime_value',
            filter_operator: 'is_greater_than',
            values: ['100.25'],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(account, first_user, params).perform

        expect(result[:contacts].pluck(:id)).to eq([cs_contact.id])
      end

      it 'rejects invalid custom date comparison values' do
        malicious_value = "2024-01-01'::date OR (SELECT pg_sleep(5)) IS NOT NULL --"
        params[:payload] = [
          {
            attribute_key: 'signed_in_at',
            filter_operator: 'is_less_than',
            values: [malicious_value],
            query_operator: nil
          }.with_indifferent_access
        ]

        expect { filter_service.new(account, first_user, params).perform }.to raise_error(CustomExceptions::CustomFilter::InvalidValue)
      end
    end
  end
end
