# Test-only migration for docker/test/zero_downtime_test.sh: it always fails.
class ZdtBadMigration < ActiveRecord::Migration[7.1]
  def change
    raise 'zero-downtime test: simulated bad migration'
  end
end
