require 'rails_helper'
describe SystemUserListener do
  include ActiveJob::TestHelper
  # let(:listener) { described_class.instance }

  describe '#account_created' do
    let!(:system_user_1) { create(:system_user) }
    let!(:system_user_2) { create(:system_user) }

    it 'adds system users' do
      perform_enqueued_jobs(only: EventDispatcherJob) do
        Account.create(name: 'test')
      end
      expect(Account.last.users.count).to eq(2)
    end
  end

  describe '#system_user_created' do
    let!(:account_1) { create(:account) }
    let!(:account_2) { create(:account) }

    it 'adds accounts to system user' do
      perform_enqueued_jobs(only: EventDispatcherJob) do
        create(:system_user)
        create(:system_user)
      end
      expect(Account.last.users.count).to eq(2)
    end
  end
end
