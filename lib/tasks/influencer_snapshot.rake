namespace :influencers do
  desc 'Export influencer snapshot for an account'
  task :export_snapshot, %i[account_id slug] => :environment do |_t, args|
    account = Account.find(args[:account_id])
    slug = args[:slug].presence || account.name.parameterize
    output_path = Rails.root.join('db', 'influencer_snapshots', "#{slug}.json")

    path = Influencers::SnapshotExporter.new(account: account, output_path: output_path).perform

    puts "Exported #{account.influencer_profiles.count} influencer profiles to #{path}"
  end

  desc 'Import influencer snapshot into an account'
  task :import_snapshot, %i[account_id path] => :environment do |_t, args|
    account = Account.find(args[:account_id])
    snapshot_path = Pathname(args[:path].presence || Rails.root.join('db', 'influencer_snapshots', "#{account.name.parameterize}.json"))

    imported_count = Influencers::SnapshotImporter.new(account: account, snapshot_path: snapshot_path).perform

    puts "Imported #{imported_count} influencer profiles into account #{account.id}"
  end
end
