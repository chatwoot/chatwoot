# frozen_string_literal: true

# AirysChat SaaS module railtie – loads custom Rake tasks
class SaasTasksRailtie < Rails::Railtie
  rake_tasks do
    Dir[File.join(__dir__, 'lib/tasks/**/*.rake')].each { |f| load f }
  end
end
