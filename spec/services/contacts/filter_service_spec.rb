require 'rails_helper'

describe ::Contacts::FilterService do
  subject(:filter_service) { described_class }

  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:custom_attribute_definition) do
    create(:custom_attribute_definition, account: account, attribute_model: 'contact_attribute', attribute_display_type: 'text')
  end
  let!(:contact) { create(:contact, account: account, additional_attributes: { 'browser_language': 'en' }) }

  before do
    create(:inbox_member, user: user_1, inbox: inbox)
    create(:inbox_member, user: user_2, inbox: inbox)
    create(:conversation, account: account, inbox: inbox, assignee: user_1, contact: contact)
    create(:conversation, account: account, inbox: inbox)
    Current.account = account
  end

  describe '#perform' do
    context 'with query present' do
      let!(:params) { { payload: [], page: 1 } }
      let(:payload) do
        [
          {
            attribute_key: 'browser_language',
            filter_operator: 'equal_to',
            values: ['en'],
            query_operator: 'AND'
          }.with_indifferent_access,
          {
            attribute_key: 'name',
            filter_operator: 'equal_to',
            values: [contact.name],
            query_operator: nil
          }.with_indifferent_access
        ]
      end

      it 'filter contacts by additional_attributes' do
        params[:payload] = payload
        result = filter_service.new(params, user_1).perform
        expect(result[:contacts].length).to be 1
      end

      it 'filter contact by tags' do
        Contact.last.update_labels('support')
        label_id = Contact.last.labels.last.id
        params[:payload] = [
          {
            attribute_key: 'labels',
            filter_operator: 'equal_to',
            values: [label_id],
            query_operator: nil
          }.with_indifferent_access
        ]

        result = filter_service.new(params, user_1).perform
        expect(result[:contacts].length).to be 1
      end

      it 'filter by custom_attributes' do
        Contact.last.update!(custom_attributes: { custom_attribute_definition.attribute_key.to_sym => 'test custom data' })
        params[:payload] = [
          {
            attribute_key: custom_attribute_definition.attribute_key,
            filter_operator: 'equal_to',
            values: ['test custom data'],
            query_operator: nil
          }.with_indifferent_access
        ]
        result = filter_service.new(params, user_1).perform
        expect(result[:contacts].length).to be 1
      end
    end
  end
end
