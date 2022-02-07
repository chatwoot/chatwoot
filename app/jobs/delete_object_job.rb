class DeleteObjectJob < ApplicationJob
  queue_as :default

  def perform(object)
    object.destroy!
  end
end
