module TestData
  def self.generate
    Orchestrator.call
  end

  def self.cleanup
    CleanupService.call
  end
end

require_relative 'test_data/constants'
require_relative 'test_data/database_optimizer'
require_relative 'test_data/cleanup_service'
require_relative 'test_data/account_creator'
require_relative 'test_data/inbox_creator'
require_relative 'test_data/display_id_tracker'
require_relative 'test_data/contact_batch_service'
require_relative 'test_data/orchestrator'
