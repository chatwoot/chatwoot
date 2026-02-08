require_relative '../test_data'

namespace :data do
  desc 'Generate large, distributed test data'
  task generate_distributed_data: :environment do
    if Rails.env.production?
      puts 'Generating large amounts of data in production can have serious performance implications.'
      puts 'Exiting to avoid impacting a live environment.'
      exit
    end

    # Configure logger
    Rails.logger = ActiveSupport::Logger.new($stdout)
    Rails.logger.formatter = proc do |severity, datetime, _progname, msg|
      "#{datetime.strftime('%Y-%m-%d %H:%M:%S.%L')} #{severity}: #{msg}\n"
    end

    begin
      TestData::DatabaseOptimizer.setup
      TestData.generate
    ensure
      TestData::DatabaseOptimizer.restore
    end
  end

  desc 'Clean up existing test data'
  task cleanup_test_data: :environment do
    TestData.cleanup
  end
end
