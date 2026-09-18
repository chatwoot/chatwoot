require 'rails_helper'

RSpec.describe DataExport do
  it 'cleans up owned export attachments when the account is deleted' do
    account = create(:account)
    record = account.data_exports.create!(name: 'Owned export', export_options: { column_names: ['email'] },
                                          export_file: { io: StringIO.new('email'), filename: 'contacts.csv' })
    account.destroy!
    expect(described_class.exists?(record.id)).to be(false)
    expect(ActiveStorage::Attachment.where(record_type: 'DataExport', record_id: record.id)).to be_empty
  end
end
