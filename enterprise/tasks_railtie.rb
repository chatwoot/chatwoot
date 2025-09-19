# frozen_string_literal: true

class TasksRailtie < Rails::Railtie
  rake_tasks do
    # Load all rake tasks from enterprise/lib/tasks
    Dir.glob(Rails.root.join('enterprise/lib/tasks/**/*.rake')).each { |f| load f }
  end
end
