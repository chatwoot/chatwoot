require 'rails_helper'

RSpec.describe DataImportErrorFinder do
  let(:data_import) { create(:data_import, :intercom) }

  it 'returns only the latest five non-skip errors' do
    6.times do |index|
      data_import.import_errors.create!(
        error_code: 'Intercom::Error',
        source_object_id: "error_#{index}",
        details: { kind: 'run_error' },
        created_at: Time.zone.at(index)
      )
    end
    data_import.import_errors.create!(
      error_code: 'Intercom::Skipped',
      source_object_id: 'skipped_error',
      details: { kind: 'skipped' },
      created_at: Time.zone.at(10)
    )

    errors = described_class.new(data_import).import_errors

    expect(errors.pluck(:source_object_id)).to eq(%w[error_5 error_4 error_3 error_2 error_1])
  end
end
