module Digitaltolk
  class ChangeContactKindService
    KIND_LABELS = {
      1 => 'tolk_contact',
      2 => 'kund_contact',
      3 => 'översättare_contact',
      4 => 'anställd_contact',
      5 => 'övrigt_contact'
    }

    def initialize(account, conversation, contact_kind)
      @account = account
      @conversation = conversation
      @contact_kind = contact_kind
    end

    def perform
      return false unless @contact_kind.present?

      toggle_contact_kind
      toggle_contact_kind_labels
    end

    private

    def toggle_contact_kind_labels
      return unless @account.feature_enabled?('required_contact_type')

      updated_labels = (@conversation.cached_label_list_array - KIND_LABELS.values + [KIND_LABELS[@contact_kind]]).uniq
      @conversation.update_labels(updated_labels)
    end

    def toggle_contact_kind
      @conversation.update!(contact_kind: @contact_kind)
    end
  end
end
