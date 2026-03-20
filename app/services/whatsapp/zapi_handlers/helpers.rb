module Whatsapp::ZapiHandlers::Helpers
  include Whatsapp::IncomingMessageServiceHelpers

  private

  def raw_message_id
    @raw_message[:isEdit] ? @raw_message[:editMessageId] : @raw_message[:messageId]
  end

  def incoming_message?
    !@raw_message[:fromMe]
  end

  def acquire_message_processing_lock
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{raw_message_id}")
    Redis::Alfred.set(key, true, nx: true, ex: 1.day)
  end

  def clear_message_source_id_from_redis
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{raw_message_id}")
    Redis::Alfred.delete(key)
  end

  def message_under_process?
    key = format(Redis::RedisKeys::MESSAGE_SOURCE_KEY, id: "#{inbox.id}_#{raw_message_id}")
    Redis::Alfred.get(key)
  end

  def with_zapi_contact_lock(phone, timeout: 5.seconds)
    raise ArgumentError, 'A block is required for with_zapi_contact_lock' unless block_given?

    start_time = Time.now.to_i
    key = "ZAPI::CONTACT_LOCK::#{phone}"

    while (Time.now.to_i - start_time) < timeout
      break if Redis::Alfred.set(key, 1, nx: true, ex: timeout)

      sleep(0.1)
    end

    yield
  ensure
    Redis::Alfred.delete(key)
  end
end
