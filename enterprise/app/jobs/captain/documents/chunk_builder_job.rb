class Captain::Documents::ChunkBuilderJob < ApplicationJob
  queue_as :low

  def perform(document)
    Captain::Documents::ChunkBuilderService.new(document).process
  end
end
