namespace :generate do
  desc "Generate WorkingHours for AccountUser's Inboxes if none exist"
  task working_hours_on_account_user: :environment do
    total      = AccountUser.count
    created    = 0
    skipped    = 0
    failed     = 0

    puts "Processing #{total} AccountUsers..."

    AccountUser.find_each.with_index(1) do |account_user, index|
      begin
        if account_user.working_hours.empty?
          account_user.send(:create_default_working_hours)
          created += 1
        else
          puts "⚠️ AccountUser #{account_user.id} already has working hours"
          skipped += 1
        end
      rescue => e
        puts "❌ Failed for AccountUser #{account_user.id}: #{e.message}"
        failed += 1
      end

      puts "Progress: #{index}/#{total}" if index % 100 == 0
    end

    puts "✅ Task finished"
    puts "  Created: #{created}"
    puts "  Skipped: #{skipped}"
    puts "  Failed:  #{failed}"

    remaining = AccountUser.left_outer_joins(:working_hours).where(working_hours: { id: nil }).count
    if remaining.zero?
      puts "🎉 All AccountUsers now have working hours"
    else
      puts "⚠️ #{remaining} AccountUsers are still missing working hours"
    end
  end
end
