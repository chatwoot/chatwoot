class Migration::FixClosedActivityJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    Digitaltolk::Tasks::FixClosedActivity.new.perform
  end
end
