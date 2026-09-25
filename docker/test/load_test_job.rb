# Test-only job for docker/test/zero_downtime_test.sh.
# It is not part of the production code path: docker/test/compose.test.yaml mounts this
# directory into the sidekiq container and loads this file with `sidekiq -r`.
require '/app/config/environment'

class SlowTestJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: false

  # Non-idempotent side effect: one line per completed run.
  # A dropped job leaves a gap in the log, a job that ran twice leaves a duplicate.
  def perform(job_id)
    sleep ENV.fetch('ZDT_JOB_SECONDS', 15).to_f
    File.open('/zdt-results/completions.log', 'a') { |file| file.puts(job_id) }
  end
end
