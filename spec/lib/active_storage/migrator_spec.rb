require 'rails_helper'

RSpec.describe ActiveStorage::Migrator do
  describe '.migrate' do
    let(:from_service_stub) { instance_double(ActiveStorage::Service) }
    let(:to_service_stub) { instance_double(ActiveStorage::Service) }

    before do
      allow(ActiveStorage::Service).to receive(:configure).with('local', any_args).and_return(from_service_stub)
      allow(ActiveStorage::Service).to receive(:configure).with('amazon', any_args).and_return(to_service_stub)
    end

    context 'when services are configured correctly' do
      it 'migrates blobs from one service to another' do
        expect(ActiveStorage::Service).to receive(:configure).with('local', any_args)
        expect(ActiveStorage::Service).to receive(:configure).with('amazon', any_args)
        expect(described_class).to receive(:migrate_blobs).with(from_service_stub, to_service_stub)
        expect { described_class.migrate('local', 'amazon') }.not_to raise_error
      end
    end

    context 'when services are not configured correctly' do
      it 'prints an error message' do
        allow(ActiveStorage::Service).to receive(:configure).and_return(nil)
        expect do
          described_class.migrate('random', 'random')
        end.to raise_error(RuntimeError, "Error: The services 'random' or 'random' are not configured correctly.")
      end
    end
  end
end
