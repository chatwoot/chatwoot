class BackupJob < ApplicationJob
  queue_as :low
  require 'rake'
  def perform
    Rake::Task.clear
    Chatwoot::Application.load_tasks
    Rake::Task['db:backup'].invoke
  end
end
