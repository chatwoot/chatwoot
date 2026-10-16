require 'rails_helper'

RSpec.describe DataImports::Intercom::CredentialsValidator do
  let(:client) { instance_double(DataImports::Intercom::Client) }

  before do
    allow(DataImports::Intercom::Client).to receive(:new).with(access_token: 'intercom-token').and_return(client)
    allow(client).to receive(:list_contacts)
    allow(client).to receive(:list_conversations)
  end

  it 'validates and counts only contacts when conversations are not selected' do
    allow(client).to receive(:list_contacts).with(per_page: 1).and_return('total_count' => 42)

    totals = described_class.new(access_token: ' intercom-token ', import_types: %w[contacts]).perform

    expect(totals).to eq('contacts' => 42)
    expect(client).not_to have_received(:list_conversations)
  end

  it 'validates contact access and counts only conversations when contacts are not selected' do
    allow(client).to receive(:list_contacts).with(per_page: 1).and_return('total_count' => 42)
    allow(client).to receive(:list_conversations).with(per_page: 1).and_return('total_count' => 17)

    totals = described_class.new(access_token: 'intercom-token', import_types: %w[conversations]).perform

    expect(totals).to eq('conversations' => 17)
    expect(client).to have_received(:list_contacts).with(per_page: 1)
  end

  it 'keeps an undiscovered total absent' do
    allow(client).to receive(:list_contacts).with(per_page: 1).and_return('data' => [])

    totals = described_class.new(access_token: 'intercom-token', import_types: %w[contacts]).perform

    expect(totals).to be_empty
  end

  it 'preserves a known zero total' do
    allow(client).to receive(:list_contacts).with(per_page: 1).and_return('total_count' => 0)

    totals = described_class.new(access_token: 'intercom-token', import_types: %w[contacts]).perform

    expect(totals).to eq('contacts' => 0)
  end

  it 'rejects an empty access key before calling Intercom' do
    expect do
      described_class.new(access_token: '', import_types: %w[contacts]).perform
    end.to raise_error(ArgumentError, 'Intercom access key is required.')

    expect(DataImports::Intercom::Client).not_to have_received(:new)
  end
end
