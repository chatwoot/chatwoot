class BackfillSynapseosPipelineStages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Account.find_each do |account|
      expected_slugs = ::Synapseos::PipelineStage::DEFAULT_STAGES.map { |s| s[:slug] }
      existing_slugs = ::Synapseos::PipelineStage.where(account_id: account.id).pluck(:slug)
      next if (expected_slugs - existing_slugs).empty?

      ::Synapseos::PipelineSeeder.call(account)
    end
  end

  def down
    # No-op: removing seeded stages could orphan leads.
  end
end
