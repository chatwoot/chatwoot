require 'rails_helper'

RSpec.describe Captain::FaqImports::CleanupJob, type: :job do
  it 'deletes an unconfirmed preview after 24 hours' do
    faq_import = create(:captain_faq_import, created_at: 25.hours.ago)

    expect { described_class.perform_now(faq_import) }.to change(Captain::FaqImport, :count).by(-1)
  end

  it 'keeps recent and confirmed imports' do
    recent = create(:captain_faq_import, created_at: 23.hours.ago)
    confirmed = create(:captain_faq_import, status: :completed, confirmed_at: 25.hours.ago, created_at: 25.hours.ago)

    described_class.perform_now(recent)
    described_class.perform_now(confirmed)

    expect(Captain::FaqImport.where(id: [recent.id, confirmed.id]).count).to eq(2)
  end
end
