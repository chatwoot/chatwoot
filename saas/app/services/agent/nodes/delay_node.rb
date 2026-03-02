# frozen_string_literal: true

# Pauses execution for a configured number of seconds.
# In production, long delays should use a scheduled job instead of blocking.
class Agent::Nodes::DelayNode < BaseNode
  MAX_DELAY = 300 # 5 minutes max

  protected

  def process
    seconds = [data['seconds'] || 5, MAX_DELAY].min

    # For short delays, sleep inline. For long ones, this could be refactored
    # to use a scheduled job with run state persistence.
    sleep(seconds) if seconds.positive?

    { output: { delayed_seconds: seconds } }
  end
end
