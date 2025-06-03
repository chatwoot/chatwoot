module Labelable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :labels
  end

  def update_labels(labels = nil)
    old_labels = label_list.dup
    update!(label_list: labels)
    dispatch_label_update_event(old_labels, label_list) if is_a?(Conversation)
  end

  def add_labels(new_labels = nil)
    return if new_labels.blank?

    new_labels = Array(new_labels) # Make sure new_labels is an array
    old_labels = label_list.dup
    combined_labels = labels + new_labels
    update!(label_list: combined_labels)
    dispatch_label_update_event(old_labels, label_list) if is_a?(Conversation)
  end

  private

  def dispatch_label_update_event(old_labels, new_labels)
    return if old_labels == new_labels

    # Only for Conversation model
    return unless respond_to?(:dispatcher_dispatch)

    # Force include label_list in previous_changes to ensure the event is processed correctly
    previous_changes_with_labels = { label_list: [old_labels, new_labels] }
    dispatcher_dispatch(Conversation::CONVERSATION_UPDATED, previous_changes_with_labels)
  end
end
