class Digitaltolk::ChangeContactKindService
  KIND_LABELS = {
    1 => 'tolk_contact',
    2 => 'kund_contact',
    3 => 'översättare_contact',
    4 => 'anställd_contact',
    5 => 'övrigt_contact'
  }.freeze

  def initialize(account, conversation, contact_kind)
    @account = account
    @conversation = conversation
    @contact_kind = contact_kind.to_i

    return unless @contact_kind.zero? && contact_kind.is_a?(String)

    @contact_kind_string = contact_kind
    convert_contact_kind_string_to_integer
  end

  def perform
    return false if @contact_kind.blank?

    set_custom_attributes
    toggle_contact_kind
    toggle_contact_kind_labels
    true
  end

  private

  def convert_contact_kind_string_to_integer
    return if @contact_kind_string.blank?

    key = if @contact_kind_string.downcase.in?(KIND_LABELS.values)
            @contact_kind_string = @contact_kind_string.downcase
          else
            [@contact_kind_string.downcase, 'contact'].join('_')
          end

    @contact_kind = KIND_LABELS.key(key)
  end

  def toggle_contact_kind_labels
    return unless @account.feature_enabled?('required_contact_type')
    return if @contact_kind.blank?

    updated_labels = (@conversation.cached_label_list_array - KIND_LABELS.values + [KIND_LABELS[@contact_kind]]).uniq
    @conversation.update_labels(updated_labels)
  end

  def toggle_contact_kind
    @conversation.update!(contact_kind: @contact_kind)
  end

  def set_custom_attributes
    attrib = equivalent_attrib.presence || @contact_kind_string
    Digitaltolk::ChangeContactTypeCustomAttributesService.new(@conversation, attrib).perform
  end

  def equivalent_attrib
    return if @contact_kind.blank?

    KIND_LABELS[@contact_kind].to_s.split('_').first&.capitalize
  end
end
