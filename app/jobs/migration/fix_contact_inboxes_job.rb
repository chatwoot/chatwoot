class Migration::FixContactInboxesJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    Rake::Task['digitaltolk:fix_contact_inboxes'].invoke
  end
end
