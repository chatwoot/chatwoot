# CUSTOMIZAÇÃO_SYNAPSEOS: orchestrator for per-account defaults seeded on creation.
# Future sprints (pipelines, dashboards, canned responses) should register their
# seeders here so `Account.after_create` triggers the whole bootstrap in one place.
class Synapseos::AccountDefaults
  def self.seed(account)
    # PipelineSeeder usa `.call(account)`; demais seeders usam `new(account).perform!`.
    Synapseos::PipelineSeeder.call(account)
    Synapseos::CustomAttributesSeeder.new(account).perform!
    Synapseos::ContractLabelsSeeder.call(account)
    Synapseos::SquadronBotsSeeder.call(account)
  end
end
