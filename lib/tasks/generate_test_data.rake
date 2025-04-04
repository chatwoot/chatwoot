require_relative '../test_data'

namespace :data do
  desc 'Generate large, distributed test data'
  task generate_distributed_data: :environment do
    if Rails.env.production?
      puts 'Generating large amounts of data in production can have serious performance implications.'
      puts 'Exiting to avoid impacting a live environment.'
      exit
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
