require 'rails_helper'

RSpec.describe DataImports::Csv::NotificationJob do
  it 'sends the CSV completion notification once and links to the import page' do
    account = create(:account)
    create(:user, account: account, role: :administrator)
    record = create(:data_import, account: account, source_provider: 'csv', source_type: 'file', import_types: ['contacts'],
                                  status: :completed, total_records: 1, processed_records: 1)
    expect do
      2.times { described_class.perform_now(record) }
    end.to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(ActionMailer::Base.deliveries.last.body.encoded).to include("settings/data/#{record.id}")
  end
end
