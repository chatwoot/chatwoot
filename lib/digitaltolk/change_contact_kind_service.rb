module Digitaltolk
  class ChangeContactKindService
    KIND_LABELS = {
      1 => 'tolk_contact',
      2 => 'kund_contact',
      3 => 'översättare_contact',
      4 => 'anställd_contact',
      5 => 'övrigt_contact'
    }

    def initialize(account, conversation, contact_kind, contact_kind_string = '')
      @account = account
      @conversation = conversation
      @contact_kind = contact_kind
      @contact_kind_string = contact_kind_string
      convert_contact_kind_string_to_integer
    end

    def perform
      return false unless @contact_kind.present?

      set_custom_atributes
      toggle_contact_kind
      toggle_contact_kind_labels
    end

    private

    def convert_contact_kind_string_to_integer
      return unless @contact_kind_string.present?

      key = [@contact_kind_string.downcase, 'contact'].join('_')
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

    def set_custom_atributes
      if @contact_kind.present? && equivalent_label.present?
        attrs = @conversation.custom_attributes || {}
        attrs['contact_type'] = equivalent_label

        @conversation.update_column(:custom_attributes, attrs)
      end
    end

    def equivalent_label
      return unless @contact_kind.present?

      KIND_LABELS[@contact_kind].to_s.split('_').first&.capitalize
    end
  end
end
