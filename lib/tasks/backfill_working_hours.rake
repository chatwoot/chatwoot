namespace :backfill do
  desc "Populate workable_type/workable_id for existing WorkingHours"
  task working_hours: :environment do
    WorkingHour.where(workable_id: nil).find_each do |wh|
      if wh.inbox_id.present?
        wh.update!(
          workable_id: wh.inbox_id,
          workable_type: "Inbox"
        )
      else
        puts "⚠️ WorkingHour #{wh.id} has no inbox_id"
      end
    end
  end
end

# bundle exec rake backfill:working_hours
