require_relative '../test_data'

# Helper method to configure logger for test data tasks
def configure_test_data_logger
  Rails.logger = ActiveSupport::Logger.new($stdout)
  Rails.logger.formatter = proc do |severity, datetime, _progname, msg|
    "#{datetime.strftime('%Y-%m-%d %H:%M:%S.%L')} #{severity}: #{msg}\n"
  end
end

# Helper method to check production environment
def check_production_environment
  return unless Rails.env.production?

  puts 'Generating large amounts of data in production can have serious performance implications.'
  puts 'Exiting to avoid impacting a live environment.'
  exit
end

namespace :data do
  desc 'Generate large, distributed test data'
  task generate_distributed_data: :environment do
    check_production_environment
    configure_test_data_logger

    begin
      TestData::DatabaseOptimizer.setup
      TestData.generate
    ensure
      TestData::DatabaseOptimizer.restore
    end
  end

  desc 'Clean up existing test data'
  task cleanup_test_data: :environment do
    check_production_environment
    configure_test_data_logger
    TestData.cleanup
  end

  desc 'Generate contacts only for company migration testing'
  task generate_contacts: :environment do
    check_production_environment
    configure_test_data_logger

    begin
      TestData::DatabaseOptimizer.setup
      TestData::ContactsOrchestrator.call
    ensure
      TestData::DatabaseOptimizer.restore
    end
  end

  desc 'Clean up contacts test data'
  task cleanup_contacts: :environment do
    check_production_environment
    configure_test_data_logger
    TestData::ContactsCleanupService.call
  end
end
