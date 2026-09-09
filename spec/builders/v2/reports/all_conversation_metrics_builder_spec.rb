require 'rails_helper'

RSpec.describe V2::Reports::AllConversationMetricsBuilder do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  it 'skips conversations whose contact has been deleted' do
    kept = create(:conversation, account: account, inbox: inbox)
    orphan = create(:conversation, account: account, inbox: inbox)
    orphan.update_columns(contact_id: nil, contact_inbox_id: nil) # rubocop:disable Rails/SkipsModelValidations

    rows = described_class.new(account, {}).build

    expect(rows.map { |row| row[:conversation_id] }).to eq([kept.display_id])
  end
end
