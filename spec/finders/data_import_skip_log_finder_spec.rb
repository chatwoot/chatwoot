require 'rails_helper'

RSpec.describe DataImportSkipLogFinder do
  let(:data_import) { create(:data_import, :intercom) }

  before do
    6.times do |index|
      data_import.import_errors.create!(
        error_code: 'Intercom::Skipped',
        source_object_type: 'message',
        source_object_id: "message_#{index}",
        details: { kind: 'skipped' },
        created_at: Time.zone.at(index)
      )
    end
    data_import.import_errors.create!(
      error_code: 'Intercom::Skipped',
      source_object_type: 'contact',
      source_object_id: 'contact_1',
      details: { kind: 'skipped' }
    )
  end

  it 'filters skip logs and returns only the latest five', :aggregate_failures do
    finder = described_class.new(data_import, skip_logs_type: 'message')

    expect(finder.skip_logs.pluck(:source_object_id)).to eq(%w[message_5 message_4 message_3 message_2 message_1])
    expect(finder.selected_source_object_type).to eq('message')
    expect(finder.counts_by_type).to include('message' => 6, 'contact' => 1)
  end

  it 'ignores unsupported source object filters' do
    finder = described_class.new(data_import, skip_logs_type: 'company')

    expect(finder.selected_source_object_type).to be_nil
    expect(finder.skip_logs.size).to eq(5)
  end
end
