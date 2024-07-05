namespace :sidekiq do
  desc "Clear ActionCableJobs from sidekiq's critical queue"
  task clear_action_cable_broadcast_jobs: :environment do
    queue_name = 'critical'
    queue = Sidekiq::Queue.new(queue_name)
    jobs_cleared = 0

    queue.each do |job|
      if job['wrapped'] == 'ActionCableBroadcastJob'
        job.delete
        jobs_cleared += 1
      end
    end

    puts "Cleared #{jobs_cleared} ActionCableBroadcastJob(s) from the #{queue_name} queue."
  end

  desc "Clear 'RemoveDuplicateNotificationJob' from all sidekiq queues"
  task clear_notification_jobs: :environment do
    queue_names = Sidekiq::Queue.all.map(&:name)
    jobs_cleared = 0

    queue_names.each do |queue_name|
      puts "Clearing #{queue_name} queue..."
      queue = Sidekiq::Queue.new(queue_name)
      total_jobs = queue.size
      queue.each_with_index do |job,index|
        # puts job if job's class contains "notification"
        job.delete if job['wrapped'] == "Notification::RemoveDuplicateNotificationJob"
        progress = ((index + 1).to_f / total_jobs) * 100
        print "\rProgress: #{progress.round(2)}% \r"
        $stdout.flush
      end
    end

    puts "Cleared #{jobs_cleared} NotificationJob(s) from all queues."
  end
end
