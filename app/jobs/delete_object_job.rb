class DeleteObjectJob < ApplicationJob
  queue_as :low

  def perform(object)
    object.destroy!
  end
end
