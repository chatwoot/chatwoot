# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

# Load Enterprise Edition rake tasks if they exist
enterprise_tasks_path = File.join(Rails.root, 'enterprise', 'lib', 'tasks.rb')
require enterprise_tasks_path if File.exist?(enterprise_tasks_path)
