# Load all rake tasks from the enterprise/lib/tasks directory
module Tasks
  Dir.glob(File.join(File.dirname(__FILE__), 'tasks', '*.rake')).each { |r| load r }
end
