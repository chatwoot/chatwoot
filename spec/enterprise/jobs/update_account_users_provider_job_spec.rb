require 'rails_helper'

RSpec.describe UpdateAccountUsersProviderJob, type: :job do
  let(:account) { create(:account) }
  let!(:user1) { create(:user, accounts: [account], provider: 'email') }
  let!(:user2) { create(:user, accounts: [account], provider: 'email') }
  let!(:user3) { create(:user, accounts: [account], provider: 'google') }

  describe '#perform' do
    context 'when setting provider to saml' do
      it 'updates all account users to saml provider' do
        described_class.new.perform(account.id, 'saml')

        expect(user1.reload.provider).to eq('saml')
        expect(user2.reload.provider).to eq('saml')
        expect(user3.reload.provider).to eq('saml')
      end
    end

    context 'when resetting provider to email' do
      before do
        # rubocop:disable Rails/SkipsModelValidations
        user1.update_column(:provider, 'saml')
        user2.update_column(:provider, 'saml')
        user3.update_column(:provider, 'saml')
        # rubocop:enable Rails/SkipsModelValidations
      end

      it 'updates all account users to email provider' do
        described_class.new.perform(account.id, 'email')

        expect(user1.reload.provider).to eq('email')
        expect(user2.reload.provider).to eq('email')
        expect(user3.reload.provider).to eq('email')
      end
    end

    context 'when account does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect do
          described_class.new.perform(999_999, 'saml')
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
