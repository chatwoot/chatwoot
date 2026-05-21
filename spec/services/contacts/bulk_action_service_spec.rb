require 'rails_helper'

RSpec.describe Contacts::BulkActionService do
  subject(:service) { described_class.new(account: account, user: user, params: params) }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  describe '#perform' do
    context 'when delete action is requested via action_name' do
      let(:params) { { ids: [1, 2], action_name: 'delete' } }

      it 'delegates to the bulk delete service' do
        bulk_delete_service = instance_double(Contacts::BulkDeleteService, perform: true)

        expect(Contacts::BulkDeleteService).to receive(:new)
          .with(account: account, contact_ids: [1, 2])
          .and_return(bulk_delete_service)

        service.perform
      end
    end

    context 'when labels are provided' do
      let(:params) { { ids: [10, 20], labels: { add: %w[vip support] }, extra: 'ignored' } }

      it 'delegates to the bulk assign labels service with permitted params' do
        bulk_assign_service = instance_double(Contacts::BulkAssignLabelsService, perform: true)

        expect(Contacts::BulkAssignLabelsService).to receive(:new)
          .with(account: account, contact_ids: [10, 20], labels: %w[vip support])
          .and_return(bulk_assign_service)

        service.perform
      end
    end

    context 'when labels are removed' do
      let!(:contact_one) { create(:contact, account: account) }
      let!(:contact_two) { create(:contact, account: account) }
      let!(:other_contact) { create(:contact) }
      let(:params) { { ids: [contact_one.id, contact_two.id, other_contact.id], labels: { remove: %w[vip] } } }

      before do
        contact_one.add_labels(%w[vip support])
        contact_two.add_labels(%w[vip priority])
        other_contact.add_labels(%w[vip support])
      end

      it 'removes labels from contacts that belong to the account' do
        result = service.perform

        expect(result[:success]).to be(true)
        expect(result[:updated_contact_ids]).to contain_exactly(contact_one.id, contact_two.id)
        expect(contact_one.reload.label_list).to contain_exactly('support')
        expect(contact_two.reload.label_list).to contain_exactly('priority')
        expect(other_contact.reload.label_list).to contain_exactly('vip', 'support')
      end
    end
  end
end
