# CUSTOMIZAÇÃO_SYNAPSEOS: orchestrator for per-account defaults seeded on creation.
# Future sprints (pipelines, dashboards, canned responses) should register their
# seeders here so `Account.after_create` triggers the whole bootstrap in one place.
module Synapseos
  class AccountDefaults
    SEEDERS = [
      Synapseos::CustomAttributesSeeder
    ].freeze

    def self.seed(account)
      SEEDERS.each { |seeder| seeder.new(account).perform! }
    end
  end
end
