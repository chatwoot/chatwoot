require 'rails_helper'

RSpec.describe DataImportJob, type: :job do
  subject(:job) { described_class.perform_later(data_import) }

  let!(:data_import) { create(:data_import) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(data_import)
      .on_queue('low')
  end

  it 'imports data into the account' do
    described_class.perform_now(data_import)
    expect(data_import.account.contacts.count).to eq(CSV.parse(data_import.import_file.download, headers: true).length)
  end
end
