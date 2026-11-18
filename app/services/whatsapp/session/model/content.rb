# The body of a message, provider-neutral. Inbound content is built by the connector or by
# the Uazapi translator; outbound content is built by the message sender. Reaction is
# outbound-only: inbound reactions arrive as their own event, so handlers never have to
# branch on "is this message actually a reaction".
module Whatsapp::Session::Model::Content
  Serializable = Whatsapp::Session::Model::Serializable
  MediaRef = Whatsapp::Session::Model::MediaRef

  class Text < Data.define(:body)
    include Serializable
    wire_type 'text', embed: true
  end

  # `width`, `height` and `waveform` are the caller's to fill in: the connector does not
  # decode media, and the side building the send is the one holding the file. Absent is
  # absent all the way to the wire, where a zero would be a measurement of nothing.
  class Media < Data.define(:kind, :mime, :filename, :caption, :voice_note, :size, :duration,
                            :width, :height, :waveform, :thumbnail, :ref)
    include Serializable
    wire_type 'media', embed: true
    coerce ref: MediaRef
    defaults voice_note: false

    KINDS = %w[image video audio document sticker].freeze

    # What a voice note's bubble is drawn from, and not a resolution the sender picks: the
    # field is read as a fixed-length row of bars, so a row of another length is not a
    # shorter waveform, it is a misread one. The connector refuses anything else, and
    # refusing here too is what keeps the operator from finding out after the upload.
    WAVEFORM_SAMPLES = 64
    MAX_AMPLITUDE = 100

    def initialize(**attributes)
      kind = attributes[:kind].to_s
      raise Whatsapp::Session::Errors::InvalidPayload, "unknown media kind: #{kind}" unless KINDS.include?(kind)

      validate_waveform!(attributes[:waveform])
      super(**attributes, kind: kind)
    end

    # Maps to the `file_type` enum Chatwoot attachments use.
    def attachment_file_type
      case kind
      when 'image', 'sticker' then :image
      when 'video' then :video
      when 'audio' then :audio
      else :file
      end
    end

    private

    def validate_waveform!(waveform)
      return if waveform.blank?

      unless waveform.size == WAVEFORM_SAMPLES
        raise Whatsapp::Session::Errors::InvalidPayload,
              "a waveform is #{WAVEFORM_SAMPLES} samples and that one is #{waveform.size}"
      end
      return if waveform.all? { |sample| sample.is_a?(Integer) && sample.between?(0, MAX_AMPLITUDE) }

      raise Whatsapp::Session::Errors::InvalidPayload,
            "a waveform carries amplitudes between 0 and #{MAX_AMPLITUDE}"
    end
  end

  class Location < Data.define(:latitude, :longitude, :name, :address, :live)
    include Serializable
    wire_type 'location', embed: true
    defaults live: false
  end

  class Contacts < Data.define(:contacts)
    include Serializable
    wire_type 'contacts', embed: true
    defaults contacts: []
  end

  class Reaction < Data.define(:target_id, :emoji)
    include Serializable
    wire_type 'reaction', embed: true

    def removal?
      emoji.blank?
    end
  end

  # An interactive or templated card. The parts are kept separate because that is how the
  # dashboard renders them; `preview_text` is what the message row stores as content.
  # A catalog product or order travels as a card too (`product`, `order`), because a
  # client refuses a content type it does not know. Its title and footer are the
  # connector's English fallback ("3 items", "(estimated total)"), so the text
  # of those two kinds is written here, in the locale the caller set, from the data.
  class Rich < Data.define(:kind, :title, :body, :footer, :buttons, :media, :product, :order)
    include Serializable
    wire_type 'rich', embed: true
    coerce media: Media, product: Whatsapp::Session::Model::Product, order: Whatsapp::Session::Model::Order
    defaults buttons: []

    def preview_text
      return Whatsapp::Session::CatalogText.product(product) if kind == 'product' && product
      return Whatsapp::Session::CatalogText.order(order, note: body) if kind == 'order' && order

      lines = [title, body, footer, *button_lines]
      lines.compact_blank.join("\n\n").presence
    end

    # What content_attributes['rich'] stores, matching the shape the Baileys layer
    # already persists so the message bubble renders both the same way. The product and
    # the order go whole, an empty one included: the card is drawn from them.
    def to_content_attribute
      { 'type' => kind, 'title' => title, 'body' => body, 'footer' => footer,
        'buttons' => Array(buttons).presence, 'product' => product&.to_h, 'order' => order&.to_h }.compact.presence
    end

    private

    def button_lines
      Array(buttons).map do |button|
        button = button.stringify_keys
        suffix = button['url'].presence || button['phone'].presence
        suffix ? "\u25B8 #{button['text']}: #{suffix}" : "\u25B8 #{button['text']}"
      end
    end
  end

  # `detail` names what WhatsApp sent in the body's place: the protocol message's type for
  # `protocol`, the message's arm for `unknown_type`. Absent for the other reasons, and from
  # connectors older than 0.9.0.
  class Unsupported < Data.define(:reason, :detail)
    include Serializable
    wire_type 'unsupported', embed: true

    REASONS = %w[unknown_type undecryptable unavailable masked protocol empty].freeze

    def initialize(reason:, detail: nil)
      super
    end
  end

  CLASSES = [Text, Media, Location, Contacts, Reaction, Rich, Unsupported].freeze
  BY_TYPE = CLASSES.index_by(&:wire_type).freeze

  def self.from_h(hash)
    return if hash.nil?

    type = hash['type'] || hash[:type]
    klass = BY_TYPE[type]
    raise Whatsapp::Session::Errors::InvalidPayload, "unknown content type: #{type.inspect}" if klass.nil?

    klass.from_h(hash)
  end
end
