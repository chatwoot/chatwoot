require 'rails_helper'
require 'fileutils'
require 'stringio'
require 'tmpdir'

RSpec.describe ActiveStorage::Migrator do
  around do |example|
    original_services = ActiveStorage::Blob.services
    original_service = ActiveStorage::Blob.service

    example.run
  ensure
    ActiveStorage::Blob.services = original_services
    ActiveStorage::Blob.service = original_service
  end

  describe '.migrate' do
    let(:from_service_stub) { instance_double(ActiveStorage::Service, name: 'local') }
    let(:to_service_stub) { instance_double(ActiveStorage::Service, name: 'amazon') }

    before do
      allow(ActiveStorage::Service).to receive(:configure).with('local', any_args).and_return(from_service_stub)
      allow(ActiveStorage::Service).to receive(:configure).with('amazon', any_args).and_return(to_service_stub)
    end

    context 'when services are configured correctly' do
      it 'migrates blobs from one service to another' do
        expect(ActiveStorage::Service).to receive(:configure).with('local', any_args)
        expect(described_class).to receive(:migrate_blobs).with('local', 'amazon', should_update_service_name: true)
        expect { described_class.migrate('local', 'amazon') }.not_to raise_error
      end

      it 'passes the service-name update flag to blob migration' do
        expect(described_class).to receive(:migrate_blobs).with('local', 'amazon', should_update_service_name: false)

        described_class.migrate('local', 'amazon', should_update_service_name: false)
      end

      it 'does not override the application logger' do
        allow(described_class).to receive(:migrate_blobs)

        expect(Rails).not_to receive(:logger=)

        described_class.migrate('local', 'amazon')
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

  describe '.migrate_blobs' do
    let(:from_root) { Dir.mktmpdir('active-storage-local') }
    let(:to_root) { Dir.mktmpdir('active-storage-amazon') }
    let(:other_root) { Dir.mktmpdir('active-storage-other') }
    let(:from_service) { build_disk_service('local', from_root) }
    let(:to_service) { build_disk_service('amazon', to_root) }
    let(:other_service) { build_disk_service('other', other_root) }

    before do
      allow(described_class).to receive(:configure_service).with(:amazon).and_return(to_service)
    end

    around do |example|
      original_services = ActiveStorage::Blob.services
      original_service = ActiveStorage::Blob.service

      ActiveStorage::Blob.services = {
        'local' => from_service,
        'amazon' => to_service,
        'other' => other_service
      }
      ActiveStorage::Blob.service = from_service

      example.run
    ensure
      ActiveStorage::Blob.services = original_services
      ActiveStorage::Blob.service = original_service
      FileUtils.rm_rf([from_root, to_root, other_root])
    end

    it 'uploads non-image blobs and updates their service name' do
      blob = create_blob(service_name: 'local', filename: 'invoice.pdf', content_type: 'application/pdf', content: 'pdf-content')

      described_class.migrate_blobs(:local, :amazon, should_update_service_name: true)

      expect(blob).not_to be_image
      expect(blob.reload.service_name).to eq('amazon')
      expect(to_service.download(blob.key)).to eq('pdf-content')
    end

    it 'only migrates blobs from the source service' do
      local_blob = create_blob(service_name: 'local', filename: 'audio.mp3', content_type: 'audio/mpeg', content: 'audio-content')
      other_blob = create_blob(service_name: 'other', filename: 'other.pdf', content_type: 'application/pdf', content: 'other-content')

      described_class.migrate_blobs(:local, :amazon, should_update_service_name: true)

      expect(local_blob.reload.service_name).to eq('amazon')
      expect(to_service.download(local_blob.key)).to eq('audio-content')
      expect(other_blob.reload.service_name).to eq('other')
      expect(to_service.exist?(other_blob.key)).to be(false)
      expect(other_service.download(other_blob.key)).to eq('other-content')
    end

    it 'skips missing source files and continues migration' do
      missing_blob = create_blob(service_name: 'local', filename: 'missing.pdf', content_type: 'application/pdf', content: 'missing-content')
      existing_blob = create_blob(service_name: 'local', filename: 'existing.pdf', content_type: 'application/pdf', content: 'existing-content')

      from_service.delete(missing_blob.key)

      expect do
        described_class.migrate_blobs(:local, :amazon, should_update_service_name: true)
      end.not_to raise_error

      expect(missing_blob.reload.service_name).to eq('local')
      expect(to_service.exist?(missing_blob.key)).to be(false)
      expect(existing_blob.reload.service_name).to eq('amazon')
      expect(to_service.download(existing_blob.key)).to eq('existing-content')
    end

    it 'does not update the blob service when upload fails' do
      blob = create_blob(service_name: 'local', filename: 'report.pdf', content_type: 'application/pdf', content: 'report-content')

      allow(to_service).to receive(:upload).and_raise(ActiveStorage::IntegrityError)

      expect do
        described_class.migrate_blobs(:local, :amazon, should_update_service_name: true)
      end.to raise_error(ActiveStorage::IntegrityError)

      expect(blob.reload.service_name).to eq('local')
      expect(to_service.exist?(blob.key)).to be(false)
    end

    it 'skips the blob service update when the flag is disabled' do
      blob = create_blob(service_name: 'local', filename: 'manual.pdf', content_type: 'application/pdf', content: 'manual-content')

      described_class.migrate_blobs(:local, :amazon, should_update_service_name: false)

      expect(blob.reload.service_name).to eq('local')
      expect(to_service.download(blob.key)).to eq('manual-content')
    end

    it 'does not rewrite blobs that were already migrated' do
      blob = create_blob(service_name: 'local', filename: 'archive.pdf', content_type: 'application/pdf', content: 'archive-content')

      allow(to_service).to receive(:upload).and_call_original

      2.times { described_class.migrate_blobs(:local, :amazon, should_update_service_name: true) }

      expect(to_service).to have_received(:upload).with(blob.key, an_instance_of(Tempfile), checksum: blob.checksum).once
      expect(blob.reload.service_name).to eq('amazon')
      expect(ActiveStorage::Blob.where(id: blob.id, service_name: 'local')).to be_empty
    end

    def build_disk_service(service_name, root)
      ActiveStorage::Service.configure(service_name, { service_name => { service: 'Disk', root: root } })
    end

    def create_blob(service_name:, filename:, content_type:, content:)
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(content),
        filename: filename,
        content_type: content_type,
        service_name: service_name,
        identify: false
      )
    end
  end
end
