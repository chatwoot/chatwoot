# Wire plumbing shared by every canonical value object. A Data class that includes this
# gets `from_h` (contract payload -> typed object) and `to_h` (typed object -> contract
# payload). Both sides speak string keys: that is what the JSON frames, the golden
# fixtures and the jsonb columns carry.
#
#   MessageReceived = Data.define(:message) do
#     include Serializable
#     wire_type 'message.received'
#     coerce message: InboundMessage
#     defaults message: nil
#   end
#
# A coercion value is any object answering `from_h`; wrap it in an array for a list
# member (`coerce mentions: [Address]`).
module Whatsapp::Session::Model::Serializable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # `embed: true` keeps the discriminator inside the payload itself (content objects,
    # where the type is part of the value), instead of only in the frame around it.
    def wire_type(type = nil, embed: false)
      unless type.nil?
        @wire_type = type
        @embed_wire_type = embed
      end
      @wire_type
    end

    def embed_wire_type?
      @embed_wire_type == true
    end

    def coercions
      @coercions ||= {}
    end

    def coerce(map)
      coercions.merge!(map)
    end

    # Data has no per-member defaults. Declaring them here keeps every constructor a
    # single keyword splat, which is what makes the optional-heavy payloads readable.
    def defaults(map = nil)
      @defaults = map.freeze unless map.nil?
      @defaults || {}
    end

    def from_h(hash)
      return if hash.nil?
      raise Whatsapp::Session::Errors::InvalidPayload, "#{name} expects an object, got #{hash.class}" unless hash.respond_to?(:[])

      new(**members.index_with { |member| cast(member, hash[member.to_s].nil? ? hash[member] : hash[member.to_s]) })
    end

    private

    def cast(member, value)
      return value if value.nil?

      coercion = coercions[member]
      return value if coercion.nil?
      return Array(value).map { |item| coercion.first.from_h(item) } if coercion.is_a?(Array)

      coercion.from_h(value)
    end
  end

  # What this payload is, as a string rather than as a class. Comparing classes is what
  # a reload breaks: an alias or a `described_class` captured before it holds the
  # previous generation, `case payload when Text` stops matching, and the branch falls
  # through in silence rather than raising. The wire type is the same string on both
  # sides of a reload, and it is the same string the contract uses.
  def wire_type = self.class.wire_type

  # A nil always means "not provided", so a payload that omits a member and one that
  # sends it as null behave the same and both fall back to the declared default.
  def initialize(**attributes)
    values = self.class.defaults.merge(attributes.compact)
    super(**self.class.members.index_with { |member| values[member] })
  end

  # Nils are dropped so a payload round-trips against the golden fixtures without
  # carrying members the producer never sent.
  def to_h
    payload = super.each_with_object({}) do |(key, value), acc|
      next if value.nil?

      acc[key.to_s] = dump(value)
    end
    payload['type'] = self.class.wire_type if self.class.embed_wire_type?
    payload
  end

  private

  def dump(value)
    return value.map { |item| dump(item) } if value.is_a?(Array)

    value.is_a?(Data) ? value.to_h : value
  end
end
