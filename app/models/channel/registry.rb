# Thin registry over Channel::Base subclasses, used only for enumeration and
# creation. It auto-enumerates every loaded Channel::Base subclass, so adding a
# channel model is enough for the registry to know about it (no registration
# line needed). All behavioral dispatch lives on the channel model itself.
class Channel::Registry
  # Referenced explicitly to force Zeitwerk to load every known channel subclass,
  # so `descendants` is complete even when the app is not eager-loaded (dev/test).
  # New subclasses are still picked up automatically once loaded.
  KNOWN_CHANNEL_CLASSES = %i[Whatsapp WebWidget Email Api TwilioSms Sms FacebookPage Instagram Tiktok TwitterProfile Line Telegram]
                          .map { |name| Channel.const_get(name) }.freeze

  class << self
    # Every concrete channel subclass that is loaded.
    def all
      @all ||= Channel::Base.descendants.select { |klass| klass.allocate.param_type.present? }
    end

    # Resolve a channel class from its create-slug (e.g. 'whatsapp').
    def channel_class_for(param_type)
      all.find { |klass| klass.allocate.param_type == param_type }
    end

    # The create-slug for a channel class, or nil for unknown classes.
    def param_type_for(channel_class)
      return unless channel_class

      channel_class.allocate.param_type
    end

    # Editable attributes for a channel class.
    def editable_attrs_for(channel_class)
      return [] unless channel_class

      channel_class.allocate.editable_attrs
    end

    # Create-slugs that may be created through the generic inbox endpoint.
    def createable_param_types
      all.filter_map { |klass| klass.allocate.param_type if klass.allocate.createable? }
    end
  end
end
