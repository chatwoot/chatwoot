# frozen_string_literal: true

class Reports::UpdateIdentity
  attr_reader :account, :identity
  attr_accessor :timestamp

  def initialize(account, timestamp = Time.now)
    @account = account
    @timestamp = timestamp
  end

  def incr_conversations_count(step = 1)
    update_conversations_count(:incr, step)
  end

  def decr_conversations_count(step = 1)
    update_conversations_count(:decr, step)
  end

  def incr_incoming_messages_count(step = 1)
    update_incoming_messages_count(:incr, step)
  end

  def decr_incoming_messages_count(step = 1)
    update_incoming_messages_count(:decr, step)
  end

  def incr_outgoing_messages_count(step = 1)
    update_outgoing_messages_count(:incr, step)
  end

  def decr_outgoing_messages_count(step = 1)
    update_outgoing_messages_count(:decr, step)
  end

  def incr_resolutions_count(step = 1)
    update_resolutions_count(:incr, step)
  end

  def decr_resolutions_count(step = 1)
    update_resolutions_count(:decr, step)
  end

  def update_avg_first_response_time(response_time)
    identity.avg_first_response_time.set(response_time, timestamp)
  end

  def update_avg_resolution_time(response_time)
    identity.avg_resolution_time.set(response_time, timestamp)
  end

  private

  def update_conversations_count(method, step)
    identity.conversations_count.send(method, step, timestamp)
  end

  def update_incoming_messages_count(method, step)
    identity.incoming_messages_count.send(method, step, timestamp)
  end

  def update_outgoing_messages_count(method, step)
    identity.outgoing_messages_count.send(method, step, timestamp)
  end

  def update_resolutions_count(method, step)
    identity.resolutions_count.send(method, step, timestamp)
  end
end
