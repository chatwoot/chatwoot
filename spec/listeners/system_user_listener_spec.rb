require 'rails_helper'
describe SystemUserListener do
  include ActiveJob::TestHelper

  describe '#account_created' do
    let(:system_user_1) { create(:system_user) }
    let(:system_user_2) { create(:system_user) }
    let(:account) { create(:account) }

    it 'adds system users' do
      perform_enqueued_jobs(only: EventDispatcherJob) do
        expect(system_user_1.accounts).to eq([account])
        expect(system_user_2.accounts).to eq([account])
      end
    end
  end

  describe '#system_user_created' do
    let(:system_user_1) { create(:system_user) }
    let(:system_user_2) { create(:system_user) }
    let(:account) { create(:account) }

    it 'adds accounts to system user' do
      perform_enqueued_jobs(only: EventDispatcherJob) do
        expect(system_user_1.accounts).to eq([account])
        expect(system_user_2.accounts).to eq([account])
      end
    end
  end
end
