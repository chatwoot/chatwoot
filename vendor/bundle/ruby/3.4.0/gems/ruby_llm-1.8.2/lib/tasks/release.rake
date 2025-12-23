# frozen_string_literal: true

namespace :release do # rubocop:disable Metrics/BlockLength
  desc 'Prepare for release'
  task :prepare do
    Rake::Task['release:refresh_stale_cassettes'].invoke
    sh 'overcommit --run'
    Rake::Task['models'].invoke
  end

  desc 'Remove stale cassettes and re-record them'
  task :refresh_stale_cassettes do
    max_age_days = 1
    cassette_dir = 'spec/fixtures/vcr_cassettes'

    stale_count = 0
    Dir.glob("#{cassette_dir}/**/*.yml").each do |cassette|
      age_days = (Time.now - File.mtime(cassette)) / 86_400
      next unless age_days > max_age_days

      puts "Removing stale cassette: #{File.basename(cassette)} (#{age_days.round(1)} days old)"
      File.delete(cassette)
      stale_count += 1
    end

    if stale_count.positive?
      puts "\n🗑️  Removed #{stale_count} stale cassettes"
      puts '🔄 Re-recording cassettes...'
      system('bundle exec rspec') || exit(1)
      puts '✅ Cassettes refreshed!'
    else
      puts '✅ No stale cassettes found'
    end
  end

  desc 'Verify cassettes are fresh enough for release'
  task :verify_cassettes do
    max_age_days = 1
    cassette_dir = 'spec/fixtures/vcr_cassettes'
    stale_cassettes = []

    Dir.glob("#{cassette_dir}/**/*.yml").each do |cassette|
      age_days = (Time.now - File.mtime(cassette)) / 86_400

      next unless age_days > max_age_days

      stale_cassettes << {
        file: File.basename(cassette),
        age: age_days.round(1)
      }
    end

    if stale_cassettes.any?
      puts "\n❌ Found stale cassettes (older than #{max_age_days} days):"
      stale_files = []
      stale_cassettes.each do |c|
        puts "   - #{c[:file]} (#{c[:age]} days old)"
        stale_files << File.join(cassette_dir, '**', c[:file])
      end

      puts "\nRun locally: bundle exec rake release:refresh_stale_cassettes"
      exit 1
    else
      puts "✅ All cassettes are fresh (< #{max_age_days} days old)"
    end
  end
end
