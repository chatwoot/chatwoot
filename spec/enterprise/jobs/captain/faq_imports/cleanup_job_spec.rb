require 'rails_helper'

RSpec.describe Captain::FaqImports::CleanupJob, type: :job do
  let(:rows) { [{ 'question' => 'When will it arrive?', 'answer' => 'Within two days.', 'state' => 'valid' }] }

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

  it 'clears failed import rows after 24 hours while preserving the import history' do
    faq_import = create(:captain_faq_import, status: :failed, completed_at: 25.hours.ago,
                                             rows: rows, row_count: 1, error_message: 'Import failed')
    history = faq_import.attributes.except('rows', 'updated_at')

    2.times { described_class.perform_now(faq_import) }

    expect(faq_import.reload.rows).to eq([])
    expect(faq_import.attributes.except('rows', 'updated_at')).to eq(history)
  end

  it 'keeps rows until 24 hours after failure, regardless of when the import was created' do
    faq_import = create(:captain_faq_import, status: :failed, created_at: 3.days.ago,
                                             completed_at: 23.hours.ago, rows: rows)

    described_class.perform_now(faq_import)

    expect(faq_import.reload.rows).to eq(rows)
  end

  it 'keeps rows for an import that is still preparing' do
    faq_import = create(:captain_faq_import, status: :preparing, created_at: 3.days.ago, rows: rows)

    described_class.perform_now(faq_import)

    expect(faq_import.reload.rows).to eq(rows)
  end
end
