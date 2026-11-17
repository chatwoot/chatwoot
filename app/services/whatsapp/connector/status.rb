# What an operator needs to know about the WhatsApp connector without a shell: which
# instances are registered and at what version, and, when none is, why the last start
# failed.
#
# The instances are the connector's own registry entries, which expire on their own, so
# what is listed is what is alive. The reasons are written next to them by
# docker/entrypoints/helpers/whatsapp_connector.rb, which is the only thing that knows why a
# connector it supervises did not start, and expire too once it stops retrying.
class Whatsapp::Connector::Status
  Instance = Struct.new(:id, :version, keyword_init: true)
  StartFailure = Struct.new(:instance, :error, :at, keyword_init: true)

  def instances
    @instances ||= with_redis do |redis|
      redis.smembers(Whatsapp::Connector.key('instances')).sort.filter_map do |id|
        version = redis.hget(Whatsapp::Connector.key('instance', id), 'version')
        Instance.new(id: id, version: version) if version
      end
    end
  end

  def running?
    instances.any?
  end

  # Read through the index the helper keeps next to the reasons, never by scanning: the
  # picker asks on every request while no connector runs, and the Redis is the application's.
  def start_failures
    @start_failures ||= with_redis do |redis|
      ids = redis.zrangebyscore(Whatsapp::Connector.key('embedded'), Time.now.to_i, '+inf').sort
      next [] if ids.empty?

      records = redis.mget(*ids.map { |id| Whatsapp::Connector.key('embedded', id) })
      ids.zip(records).filter_map { |id, record| start_failure(id, record) }
    end
  end

  # The reason a native inbox cannot be created now, for the picker: the newest failure,
  # when one was published.
  def last_start_error
    start_failures.max_by { |failure| failure.at.to_s }&.error
  end

  private

  # nil for a record that expired after the index was read, or that is not ours to parse.
  def start_failure(id, record)
    return unless record

    failure = JSON.parse(record, symbolize_names: true)
    StartFailure.new(instance: id, error: failure[:error], at: failure[:at])
  rescue JSON::ParserError
    nil
  end

  def with_redis(&)
    Whatsapp::Connector::Client.with_redis(&)
  end
end
