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
end
