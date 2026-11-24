require 'rails_helper'

RSpec.describe DataExports::ContactsJob do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:options) { {} }
  let(:data_export) { DataExports::CreationService.new(account: account, initiated_by: admin, options: options).perform }

  it 'owns its file, escapes formulas, and finishes with actual progress', :aggregate_failures do
    create(:contact, account: account, name: '=1+1', email: 'person@example.com')
    create(:contact, email: 'another-account@example.com')
    described_class.perform_now(data_export, data_export.active_run_id)
    expect(data_export.reload).to be_completed
    expect(data_export.processed_records).to eq(1)
    expect(data_export.total_records).to eq(1)
    contents = data_export.export_file.download
    expect(contents).to start_with("\uFEFF".b)
    expect(contents).to include("'=1+1")
    expect(contents).not_to include('another-account@example.com')
    expect(account.contacts_export).not_to be_attached
    expect { described_class.perform_now(data_export, data_export.active_run_id) }.not_to change(ActiveStorage::Blob, :count)
  end

  context 'with a label selection' do
    let(:options) { { label: 'vip', column_names: %w[email labels] } }

    it 'preserves the selected scope and column order' do
      create(:label, account: account, title: 'vip')
      contact = create(:contact, account: account, email: 'selected@example.com')
      contact.update!(label_list: ['vip'])
      create(:contact, account: account, email: 'excluded@example.com')
      described_class.perform_now(data_export, data_export.active_run_id)
      expect(data_export.export_file.download).to include('email,labels', 'selected@example.com,vip')
      expect(data_export.export_file.download).not_to include('excluded@example.com')
    end
  end

  it 'does not publish a file after the requesting user loses permission' do
    data_export
    account.account_users.find_by!(user: admin).update!(role: :agent)
    described_class.perform_now(data_export, data_export.active_run_id)
    expect(data_export.reload).to be_failed
    expect(data_export.export_file).not_to be_attached
  end

  it 'explains permission loss during generation without publishing a file' do
    create(:contact, account: account, email: 'person@example.com')
    job = described_class.new
    allow(job).to receive(:write_batch).and_wrap_original do |method, *args|
      method.call(*args)
      account.account_users.find_by!(user: admin).update!(role: :agent)
    end

    expect { job.perform(data_export, data_export.active_run_id) }.to raise_error(Pundit::NotAuthorizedError)
    expect(data_export.reload).to be_failed
    expect(data_export.error_message).to eq('The requesting user no longer has export access.')
    expect(data_export.export_file).not_to be_attached
  end

  it 'explains permission loss during upload and purges the unpublished file' do
    data_export
    allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_wrap_original do |method, **args|
      blob = method.call(**args)
      account.account_users.find_by!(user: admin).update!(role: :agent)
      blob
    end

    expect { described_class.perform_now(data_export, data_export.active_run_id) }.to raise_error(Pundit::NotAuthorizedError)
    expect(data_export.reload).to be_failed
    expect(data_export.error_message).to eq('The requesting user no longer has export access.')
    expect(data_export.export_file).not_to be_attached
    expect(ActiveStorage::PurgeJob).to have_been_enqueued
  end

  it 'keeps retry advice for an unexpected export failure' do
    job = described_class.new
    allow(job).to receive(:write_csv).and_raise(IOError, 'Storage unavailable')

    expect { job.perform(data_export, data_export.active_run_id) }.to raise_error(IOError)
    expect(data_export.reload).to be_failed
    expect(data_export.error_message).to eq('The export could not finish. Run the export again to retry.')
    expect(data_export.export_file).not_to be_attached
  end

  it 'ignores jobs from an obsolete run' do
    expect { described_class.perform_now(data_export, 'stale') }.not_to(change { data_export.reload.status })
    expect(data_export.export_file).not_to be_attached
  end

  it 'finishes an empty selection with a header-only file' do
    described_class.perform_now(data_export, data_export.active_run_id)
    expect(data_export.reload).to be_completed
    expect(data_export.total_records).to eq(0)
    expect(data_export.export_file.download.lines.size).to eq(1)
  end

  it 'rejects unsupported columns before creating an export' do
    expect do
      DataExports::CreationService.new(account: account, initiated_by: admin, options: { column_names: ['destroy!'] }).perform
    end.to raise_error(ArgumentError, 'Unsupported export columns.')
    expect(account.data_exports).to be_empty
  end
end
