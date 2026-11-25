# The envelope around an inbound event payload. On the `native` backend it mirrors a
# Redis stream entry; the Uazapi translator builds the same object with only the fields
# a webhook can carry, so the dispatcher and the handlers are identical for both.
class Whatsapp::Session::Model::Event < Data.define(:type, :payload, :id, :sid, :epoch, :seq, :ts, :inst)
  include Whatsapp::Session::Model::Serializable

  Events = Whatsapp::Session::Model::Events

  defaults epoch: 0, seq: 0

  class << self
    # `frame` is a decoded stream entry: numeric fields may still be strings, since
    # every Redis stream field is transported as one.
    def from_frame(frame)
      frame = frame.stringify_keys
      version = frame['v']
      unless Whatsapp::Session.protocol_compatible?(version)
        raise Whatsapp::Session::Errors::InvalidEvent, "event frame on protocol #{version.inspect}, this build reads " \
                                                       "#{Whatsapp::Session::MIN_PROTOCOL_VERSION}..#{Whatsapp::Session::PROTOCOL_VERSION}"
      end

      type = frame['type']
      raise Whatsapp::Session::Errors::InvalidEvent, 'event frame without a type' if type.blank?

      new(
        type: type, payload: Events.build(type, frame['payload']), id: frame['id'], sid: frame['sid'],
        epoch: frame['epoch'].to_i, seq: frame['seq'].to_i, ts: frame['ts']&.to_i, inst: frame['inst']
      )
    end

    # Builds an event around an already-typed payload, deriving the wire type from it.
    def build(payload, **attributes)
      new(type: payload.class.wire_type, payload: payload, **attributes)
    end
  end

  def to_frame
    {
      'v' => Whatsapp::Session::PROTOCOL_VERSION, 'id' => id, 'type' => type, 'sid' => sid,
      'epoch' => epoch, 'seq' => seq, 'ts' => ts, 'inst' => inst, 'payload' => payload_to_h
    }.compact
  end

  # Ordering token: monotonic per session, and comparable across a lease handover
  # because a new owner always starts a higher epoch.
  def cursor
    [epoch, seq]
  end

  def newer_than?(other_cursor)
    other_cursor.blank? || (cursor <=> other_cursor).positive?
  end

  def known?
    payload.present? && payload.wire_type != 'unknown'
  end

  def at
    Time.zone.at(ts / 1000.0) if ts
  end

  private

  def payload_to_h
    payload.is_a?(Events::Unknown) ? payload.payload : payload.to_h
  end
end
