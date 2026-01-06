require 'rails_helper'

RSpec.describe Contacts::BulkActionJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:params) { { 'ids' => [1], 'labels' => { 'add' => ['vip'] } } }

  it 'invokes the bulk action service with account and user' do
    service_instance = instance_double(Contacts::BulkActionService, perform: true)

    allow(Contacts::BulkActionService).to receive(:new).and_return(service_instance)

    described_class.perform_now(account.id, user.id, params)

    expect(Contacts::BulkActionService).to have_received(:new).with(
      account: account,
      user: user,
      params: params
    )
    expect(service_instance).to have_received(:perform)
  end
end
