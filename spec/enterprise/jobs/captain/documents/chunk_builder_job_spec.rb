require 'rails_helper'

RSpec.describe Captain::Documents::ChunkBuilderJob, type: :job do
  let(:document) { create(:captain_document, status: :available) }
  let(:builder_service) { instance_double(Captain::Documents::ChunkBuilderService) }

  describe '#perform' do
    it 'runs the chunk builder service for the document' do
      allow(Captain::Documents::ChunkBuilderService).to receive(:new).with(document).and_return(builder_service)
      allow(builder_service).to receive(:process)

      described_class.new.perform(document)

      expect(Captain::Documents::ChunkBuilderService).to have_received(:new).with(document)
      expect(builder_service).to have_received(:process)
    end

    it 'bubbles service errors for retry handling' do
      allow(Captain::Documents::ChunkBuilderService).to receive(:new).with(document).and_return(builder_service)
      allow(builder_service).to receive(:process).and_raise(StandardError, 'transient failure')

      expect { described_class.new.perform(document) }.to raise_error(StandardError, 'transient failure')
    end
  end
end
