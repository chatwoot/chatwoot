require 'rails_helper'

RSpec.describe Labels::RemoveAssociationsJob do
  subject(:job) { described_class.perform_later(label_title: label_title, account_id: account_id) }

  let(:label_title) { 'billing' }
  let(:account_id) { 1 }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(label_title: label_title, account_id: account_id)
      .on_queue('default')
  end
end
