# Current is thread-local and a Sidekiq thread outlives the jobs that run on it, so a job
# that writes Current without cleaning up hands its values to whatever runs next on that
# thread -- as a record that may not even be reachable any more.
#
# The web side already closes this at the request boundary, in
# RequestExceptionHandler#handle_with_exception. This is the same boundary for jobs.
#
# Deliberately only on the way out: a job that needs Current sets its own, since nothing
# about Current crosses the queue. Clearing on entry would say otherwise.
class CurrentResetMiddleware
  def call(_worker, _job, _queue)
    yield
  ensure
    Current.reset
  end
end
