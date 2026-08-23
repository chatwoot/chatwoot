# The abstract superclass for all chat channels. A channel owns its own behavior
# (capabilities): outbound send service, messaging window, markdown renderer,
# campaign strategy, source-id generation, and the predicates that let the rest
# of the app ask the channel what it can do. Everything else dispatches through
# these capabilities instead of switching on `channel_type` strings.
#
# To add a new channel type, subclass this and override the relevant
# capabilities, then (if not auto-enumerated) register it in ChannelRegistry.
class Channel::Base < ApplicationRecord
  class Unsupported < StandardError; end

  include Channelable
  self.abstract_class = true

  MESSAGING_WINDOW_24_HOURS = 24.hours
  MESSAGING_WINDOW_7_DAYS = 7.days

  # Create-slug used to build this channel from the inbox creation endpoint
  # (e.g. 'whatsapp'). Returns nil for channels that are not created through the
  # generic endpoint (OAuth-backed channels use their own callbacks).
  def param_type
    nil
  end

  # Whether this channel can be created through the generic inbox creation
  # endpoint (as opposed to OAuth callbacks / dedicated controllers).
  def createable?
    true
  end

  # User-facing name of the channel (drives the inbox `inbox_type`).
  def friendly_name
    name
  end

  # Attributes the generic inbox-creation endpoint permits for this channel.
  def editable_attrs
    self.class.const_defined?(:EDITABLE_ATTRS) ? self.class::EDITABLE_ATTRS : []
  end

  # Outbound send service class (responds to `new(message:).perform`), or nil.
  def send_service
    nil
  end

  # Campaign strategy: `{ supported:, one_off:, campaignable:, service: }`, or
  # nil when the channel cannot host a campaign.
  def campaign_definition
    nil
  end

  # Duration during which an agent may reply after an inbound message, or nil to
  # always allow replies.
  def messaging_window
    nil
  end

  # Markdown renderer method used by Messages::MarkdownRendererService.
  def renderer
    :render_html
  end

  # Maximum length of an outgoing message this channel accepts.
  def message_length_limit
    Captain::MessageLengthLimit::DEFAULT
  end

  # Generate the contact-inbox source id for a contact. Raises Unsupported when
  # this channel type cannot derive one, and ActionController::ParameterMissing
  # when a required contact field is absent.
  def source_id_for(_contact)
    raise Unsupported, "source id generation is not supported for #{self.class}"
  end

  # Webhook URL to which the channel platform delivers inbound events, or nil.
  def callback_webhook_url
    nil
  end

  # Predicates — a channel overrides the ones it represents. Default all false.
  def sms? = false
  def facebook? = false
  def instagram? = false
  def instagram_direct? = false
  def tiktok? = false
  def web_widget? = false
  def api? = false
  def email? = false
  def twilio? = false
  def twitter? = false
  def telegram? = false
  def line? = false
  def whatsapp? = false
  def twilio_whatsapp? = false

  protected

  def meta_messaging_window(config_key)
    GlobalConfigService.load(config_key, nil) ? MESSAGING_WINDOW_7_DAYS : MESSAGING_WINDOW_24_HOURS
  end
end
