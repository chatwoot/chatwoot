module ConversationLabelPropagation
  extend ActiveSupport::Concern

  included do
    after_update_commit :propagate_label_changes_to_contact_and_siblings, if: :label_list_previously_changed?
    after_create_commit :inherit_contact_labels_on_creation
  end

  private

  def label_list_previously_changed?
    previous_changes.key?(:label_list) || previous_changes.key?('label_list')
  end

  def inherit_contact_labels_on_creation
    return if Current.label_propagation_in_progress
    return if contact.blank?

    inherited = contact.label_list.to_a
    return if inherited.empty?

    merged = (label_list + inherited).uniq
    return if merged.sort == label_list.sort

    Current.label_propagation_in_progress = true
    begin
      update_labels(merged)
    ensure
      Current.label_propagation_in_progress = false
    end
  end

  def propagate_label_changes_to_contact_and_siblings
    return if Current.label_propagation_in_progress
    return if contact.blank?

    diff = compute_conversation_label_diff(previous_changes)
    return if diff.nil?

    Current.label_propagation_in_progress = true
    begin
      added, removed = diff
      sync_contact_with_diff(added, removed)
      fan_diff_out_to_siblings(added, removed)
    ensure
      Current.label_propagation_in_progress = false
    end
  end

  def compute_conversation_label_diff(changes_hash)
    changes = changes_hash[:label_list] || changes_hash['label_list']
    return nil unless changes.is_a?(Array)

    previous_labels, current_labels = changes
    return nil unless previous_labels.is_a?(Array) && current_labels.is_a?(Array)

    added   = current_labels - previous_labels
    removed = previous_labels - current_labels
    return nil if added.empty? && removed.empty?

    [added, removed]
  end

  def sync_contact_with_diff(added, removed)
    next_contact_labels = (contact.label_list + added - removed).uniq
    return if next_contact_labels.sort == contact.label_list.sort

    contact.update_labels(next_contact_labels)
  end

  def fan_diff_out_to_siblings(added, removed)
    # Only fan out to open sibling conversations; closed/resolved/snoozed
    # conversations should not be re-tagged retroactively.
    contact.conversations.where(status: :open).where.not(id: id).find_each do |sibling|
      next_labels = (sibling.label_list + added - removed).uniq
      sibling.update_labels(next_labels) unless next_labels.sort == sibling.label_list.sort
    end
  end
end
