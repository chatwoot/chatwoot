# The envelope around an outbound command payload. `reply_to` is set for RPC commands
# (the list the connector pushes the reply to).
#
# The two ceilings are different requests and a command may carry either, both or
# neither. `deadline` is an instant and says "do not start this after that moment": one
# that reaches its owner late is refused, unrun. `max_runtime_ms` is a duration counted
# from the moment the work begins and says "do not let this run longer than that", with
# nothing to say about arriving late. A teardown needs the second without the first,
# which is why one field could not stand for both.
class Whatsapp::Session::Model::Command < Data.define(:type, :payload, :id, :sid, :ts, :reply_to, :deadline,
                                                      :max_runtime_ms, :idempotency_key)
  include Whatsapp::Session::Model::Serializable

  Commands = Whatsapp::Session::Model::Commands

  class << self
    def build(payload, **attributes)
      new(type: payload.class.wire_type, payload: payload, **attributes)
    end

    def from_frame(frame)
      frame = frame.stringify_keys
      version = frame['v']
      unless Whatsapp::Session.protocol_compatible?(version)
        raise Whatsapp::Session::Errors::InvalidPayload, "command frame on protocol #{version.inspect}, this build reads " \
                                                         "#{Whatsapp::Session::MIN_PROTOCOL_VERSION}..#{Whatsapp::Session::PROTOCOL_VERSION}"
      end

      type = frame['type']
      new(
        type: type, payload: Commands.build(type, frame['payload']), id: frame['id'], sid: frame['sid'],
        ts: frame['ts']&.to_i, reply_to: frame['reply_to'], deadline: frame['deadline']&.to_i,
        max_runtime_ms: frame['max_runtime_ms']&.to_i, idempotency_key: frame['idempotency_key']
      )
    end
  end

  def to_frame
    {
      'v' => Whatsapp::Session::PROTOCOL_VERSION, 'id' => id, 'type' => type, 'sid' => sid, 'ts' => ts,
      'reply_to' => reply_to, 'deadline' => deadline, 'max_runtime_ms' => max_runtime_ms,
      'idempotency_key' => idempotency_key, 'payload' => payload.to_h
    }.compact
  end

  def rpc?
    Commands.rpc?(type)
  end
end
