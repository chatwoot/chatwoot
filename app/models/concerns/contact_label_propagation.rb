module ContactLabelPropagation
  extend ActiveSupport::Concern

  included do
    after_update_commit :propagate_label_changes_to_conversations, if: :label_list_previously_changed?
  end

  private

  def label_list_previously_changed?
    previous_changes.key?(:label_list) || previous_changes.key?('label_list')
  end

  def propagate_label_changes_to_conversations
    return if Current.label_propagation_in_progress

    diff = compute_label_diff(previous_changes)
    return if diff.nil?

    Current.label_propagation_in_progress = true
    begin
      apply_diff_to_conversations(*diff)
    ensure
      Current.label_propagation_in_progress = false
    end
  end

  def compute_label_diff(changes_hash)
    changes = changes_hash[:label_list] || changes_hash['label_list']
    return nil unless changes.is_a?(Array)

    previous_labels, current_labels = changes
    return nil unless previous_labels.is_a?(Array) && current_labels.is_a?(Array)

    added   = current_labels - previous_labels
    removed = previous_labels - current_labels
    return nil if added.empty? && removed.empty?

    [added, removed]
  end

  def apply_diff_to_conversations(added, removed)
    # Propagate only to open conversations. Resolved / pending / snoozed
    # conversations stay frozen with whatever labels they had at the time
    # they left the open state — re-tagging a resolved conversation when an
    # attribute on the contact changes would rewrite history.
    conversations.where(status: :open).find_each do |conv|
      next_labels = (conv.label_list + added - removed).uniq
      conv.update_labels(next_labels) unless next_labels.sort == conv.label_list.sort
    end
  end
end
