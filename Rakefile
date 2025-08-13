# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

# Load Enterprise Edition rake tasks if they exist
enterprise_tasks_path = Rails.root.join('enterprise/lib/tasks').to_s
Dir.glob(File.join(enterprise_tasks_path, '*.rake')).each { |r| load r } if File.directory?(enterprise_tasks_path)
