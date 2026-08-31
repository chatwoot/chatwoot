require 'rails_helper'

RSpec.describe Labels::RemoveAssociationsJob do
  subject(:job) do
    described_class.perform_later(
      label_title: label_title,
      account_id: account_id,
      label_deleted_at: label_deleted_at
    )
  end

  let(:label_title) { 'billing' }
  let(:account_id) { 1 }
  let(:label_deleted_at) { Time.current }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(label_title: label_title, account_id: account_id, label_deleted_at: label_deleted_at)
      .on_queue('default')
  end
end
