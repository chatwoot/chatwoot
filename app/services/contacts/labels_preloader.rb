module Contacts
  class LabelsPreloader
    LABELS_CONTEXT = 'labels'.freeze

    def self.call(account:, contact_ids:)
      new(account: account, contact_ids: contact_ids).perform
    end

    def initialize(account:, contact_ids:)
      @account = account
      @contact_ids = Array(contact_ids).compact.uniq
    end

    def perform
      return {} if @contact_ids.blank?

      approved_labels = @account.labels.pluck(:title)
      return @contact_ids.index_with { [] } if approved_labels.blank?

      labels_by_id = Hash.new { |hash, contact_id| hash[contact_id] = [] }

      ActsAsTaggableOn::Tagging
        .joins(:tag)
        .where(context: LABELS_CONTEXT, taggable_type: 'Contact', taggable_id: @contact_ids)
        .where(tags: { name: approved_labels })
        .pluck(:taggable_id, 'tags.name')
        .each { |contact_id, label| labels_by_id[contact_id] << label }

      @contact_ids.index_with { |contact_id| labels_by_id[contact_id] }
    end
  end
end
