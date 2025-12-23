# These tasks are added to the project if you install annotate as a Rails plugin.
# (They are not used to build annotate itself.)

# Append annotations to Rake tasks for ActiveRecord, so annotate automatically gets
# run after doing db:migrate.

# Migration tasks are tasks that we'll "hook" into
migration_tasks = %w[db:migrate db:migrate:up db:migrate:down db:migrate:reset db:migrate:redo db:rollback]

# Support for data_migrate gem (https://github.com/ilyakatz/data-migrate)
migration_tasks_with_data = migration_tasks.map { |task| "#{task}:with_data" }
migration_tasks += migration_tasks_with_data

if defined?(Rails::Application) && Rails.version.split(".").first.to_i >= 6
  require "active_record"

  databases = ActiveRecord::Tasks::DatabaseTasks.setup_initial_database_yaml

  # If there's multiple databases, this appends database specific rake tasks to `migration_tasks`
  ActiveRecord::Tasks::DatabaseTasks.for_each(databases) do |database_name|
    migration_tasks.concat(%w[db:migrate db:migrate:up db:migrate:down db:rollback].map { |task| "#{task}:#{database_name}" })
  end
end

migration_tasks.each do |task|
  next unless Rake::Task.task_defined?(task)

  Rake::Task[task].enhance do # This block is ran after `task` completes
    task_name = Rake.application.top_level_tasks.last # The name of the task that was run, e.g. "db:migrate"

    Rake::Task[task_name].enhance do
      ::AnnotateRb::Runner.run(["models"])
    end
  end
end
