require 'rails_helper'

RSpec.describe Contacts::BulkRemoveLabelsService do
  subject(:service) do
    described_class.new(
      account: account,
      contact_ids: [contact_one.id, contact_two.id, other_contact.id],
      labels: labels
    )
  end

  let(:account) { create(:account) }
  let!(:contact_one) { create(:contact, account: account) }
  let!(:contact_two) { create(:contact, account: account) }
  let!(:other_contact) { create(:contact) }
  let(:labels) { %w[vip] }

  before do
    contact_one.add_labels(%w[vip support])
    contact_two.add_labels(%w[vip priority])
    other_contact.add_labels(%w[vip support])
  end

  it 'removes labels from contacts that belong to the account' do
    service.perform

    expect(contact_one.reload.label_list).to contain_exactly('support')
    expect(contact_two.reload.label_list).to contain_exactly('priority')
  end

  it 'does not remove labels from contacts outside the account' do
    service.perform

    expect(other_contact.reload.label_list).to contain_exactly('vip', 'support')
  end

  it 'returns ids of contacts that were updated' do
    result = service.perform

    expect(result[:success]).to be(true)
    expect(result[:updated_contact_ids]).to contain_exactly(contact_one.id, contact_two.id)
  end

  it 'returns success with no updates when labels are blank' do
    result = described_class.new(
      account: account,
      contact_ids: [contact_one.id],
      labels: []
    ).perform

    expect(result).to eq(success: true, updated_contact_ids: [])
    expect(contact_one.reload.label_list).to contain_exactly('vip', 'support')
  end
end
