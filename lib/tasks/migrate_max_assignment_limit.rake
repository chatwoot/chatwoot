# Manually run the max_assignment_limit to agent capacity policy migration.
# This is idempotent and safe to run multiple times.
#
# Usage:
#   bundle exec rake assignment:migrate_max_limit
namespace :assignment do
  desc 'Migrate max_assignment_limit from inbox config to agent capacity policies'
  task migrate_max_limit: :environment do
    MigrateMaxAssignmentLimitToPolicies.new.up
  end
end
