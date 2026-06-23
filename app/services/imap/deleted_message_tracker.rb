require 'digest'

class Imap::DeletedMessageTracker
  TTL = 2.days.to_i

  pattr_initialize [:inbox!]

  def record(source_ids)
    return unless inbox.email?

    keys = source_ids.compact_blank.map { |source_id| redis_key(source_id) }
    return if keys.blank?

    Redis::Alfred.pipelined do |pipeline|
      keys.each { |key| pipeline.set(key, true, ex: TTL) }
    end
  end

  def deleted?(source_id)
    Redis::Alfred.exists?(redis_key(source_id))
  end

  private

  def redis_key(source_id)
    format(Redis::RedisKeys::IMAP_DELETED_MESSAGE, inbox_id: inbox.id, message_id_digest: Digest::SHA256.hexdigest(source_id))
  end
end
