require 'rails_helper'

RSpec.describe Captain::FaqImport do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:user) { create(:user, account: account, role: :administrator) }

  it 'is destroyed with its assistant' do
    faq_import = create(:captain_faq_import, account: account, assistant: assistant, user: user)

    assistant.destroy!

    expect(described_class).not_to exist(faq_import.id)
  end

  it 'is destroyed with its account' do
    faq_import = create(:captain_faq_import, account: account, assistant: assistant, user: user)

    account.destroy!

    expect(described_class).not_to exist(faq_import.id)
  end

  it 'keeps import history when its user is deleted' do
    faq_import = create(:captain_faq_import, account: account, assistant: assistant, user: user)

    user.destroy!

    expect(faq_import.reload).to have_attributes(user_id: nil, account_id: account.id, assistant_id: assistant.id)
  end

  it 'requires an importing user when the record is created' do
    faq_import = build(:captain_faq_import, account: account, assistant: assistant, user: nil)

    expect(faq_import).not_to be_valid
    expect(faq_import.errors[:user]).to include("can't be blank")
  end

  describe '#claim_stalled_recovery!' do
    it 'allows one recovery claim during the stalled interval' do
      faq_import = create(
        :captain_faq_import,
        account: account,
        assistant: assistant,
        user: user,
        status: :preparing,
        updated_at: (described_class::STALLED_AFTER + 1.minute).ago
      )

      claimed_at = faq_import.claim_stalled_recovery!

      expect(claimed_at).to be_present
      expect(faq_import.claim_stalled_recovery!).to be_nil
    end
  end
end
