require 'rails_helper'

RSpec.describe ActiveStorage::Migrator do
  describe '.migrate' do
    let(:from_service_stub) { double('from_service') }
    let(:to_service_stub) { double('to_service') }
    let(:blob_spy) { spy('ActiveStorage::Blob') }

    before do
      allow(ActiveStorage::Service).to receive(:configure).with(:from_service, any_args).and_return(from_service_stub)
      allow(ActiveStorage::Service).to receive(:configure).with(:to_service, any_args).and_return(to_service_stub)
      allow(ActiveStorage::Blob).to receive(:find_each).and_yield(blob_spy)
    end

    context 'when services are configured correctly' do
      it 'migrates blobs from one service to another' do
        allow(blob_spy).to receive(:image?).and_return(true)

        expect(ActiveStorage::Service).to receive(:configure).with(:from_service, any_args)
        expect(ActiveStorage::Service).to receive(:configure).with(:to_service, any_args)

        described_class.migrate(:from_service, :to_service)
      end
    end

    context 'when services are not configured correctly' do
      it 'prints an error message' do
        allow(from_service_stub).to receive(:nil?).and_return(true)

        expect { described_class.migrate(:from_service, :to_service) }.to output("Error: The services 'from_service' or 'to_service' are not configured correctly.\n").to_stdout
      end
    end
  end
end
