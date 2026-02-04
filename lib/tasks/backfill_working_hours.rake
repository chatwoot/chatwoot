namespace :backfill do
  desc 'Backfill WorkingHours to use polymorphic workable (Inbox)'
  task working_hours: :environment do
    scope = WorkingHour.where(workable_id: nil)
    total = scope.count
    migrated = 0
    skipped  = 0
    failed   = 0

    puts "Migrating #{total} working hours..."

    scope.find_each.with_index(1) do |wh, index|
      if wh.inbox_id.present?
        wh.update!(workable_id: wh.inbox_id, workable_type: 'Inbox')
        migrated += 1
      else
        puts "⚠️ Skipping WorkingHour #{wh.id} (no inbox_id)"
        skipped += 1
      end

      puts "Progress: #{index}/#{total}" if index % 100 == 0
    rescue StandardError => e
      puts "❌ Failed to migrate WorkingHour #{wh.id}: #{e.message}"
      failed += 1
    end

    puts '✅ Migration finished'
    puts "  Migrated: #{migrated}"
    puts "  Skipped:  #{skipped}"
    puts "  Failed:   #{failed}"

    remaining = WorkingHour.where(workable_id: nil).count
    if remaining.zero?
      puts '🎉 All working hours migrated successfully'
    else
      puts "⚠️ #{remaining} working hours remain unmigrated"
    end
  end
end
