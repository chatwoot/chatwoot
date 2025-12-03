# frozen_string_literal: true

class TasksRailtie < Rails::Railtie
  rake_tasks do
    # Load all rake tasks from extended/lib/tasks
    Dir.glob(Rails.root.join('extended/lib/tasks/**/*.rake')).each { |f| load f }
  end
end
