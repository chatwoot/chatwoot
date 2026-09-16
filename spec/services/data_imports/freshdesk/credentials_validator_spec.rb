require 'rails_helper'

RSpec.describe DataImports::Freshdesk::CredentialsValidator do
  let(:client) { instance_double(DataImports::Freshdesk::Client) }

  before do
    allow(DataImports::Freshdesk::Client).to receive(:new).with(domain: 'acme', api_key: 'secret').and_return(client)
    allow(client).to receive(:list_contacts)
    allow(client).to receive(:list_tickets)
  end

  it 'validates only the selected Freshdesk resources and leaves totals undiscovered', :aggregate_failures do
    totals = described_class.new(domain: 'acme', api_key: ' secret ', import_types: %w[conversations]).perform

    expect(totals).to be_empty
    expect(client).to have_received(:list_tickets).with(per_page: 1)
    expect(client).not_to have_received(:list_contacts)
  end

  it 'validates contacts and tickets when both are selected', :aggregate_failures do
    described_class.new(domain: 'acme', api_key: 'secret', import_types: %w[contacts conversations]).perform

    expect(client).to have_received(:list_contacts).with(per_page: 1)
    expect(client).to have_received(:list_tickets).with(per_page: 1)
  end

  it 'rejects missing or unsupported input before calling Freshdesk', :aggregate_failures do
    expect do
      described_class.new(domain: '', api_key: 'secret', import_types: %w[contacts]).perform
    end.to raise_error(ArgumentError, 'Freshdesk domain is required.')
    expect do
      described_class.new(domain: 'acme', api_key: '', import_types: %w[contacts]).perform
    end.to raise_error(ArgumentError, 'Freshdesk API key is required.')
    expect do
      described_class.new(domain: 'acme', api_key: 'secret', import_types: %w[companies]).perform
    end.to raise_error(ArgumentError, 'Unsupported import types: companies')
    expect(DataImports::Freshdesk::Client).not_to have_received(:new)
  end
end
