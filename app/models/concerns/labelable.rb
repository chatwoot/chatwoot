module Labelable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :labels
    # Must run before the gem's own save callbacks, which write any label list that was loaded.
    before_save :discard_unassigned_label_list, prepend: true
  end

  def update_labels(labels = nil)
    update!(label_list: labels)
  end

  def add_labels(new_labels = nil)
    return if new_labels.blank?

    new_labels = Array(new_labels) # Make sure new_labels is an array
    combined_labels = labels + new_labels
    update!(label_list: combined_labels)
  end

  private

  # acts-as-taggable-on writes a label list on every save once it has been read, so an
  # unrelated save from a stale instance overwrites labels saved elsewhere. Forget a list
  # this instance did not assign, the same way the gem's reload does, so only assigned
  # labels are written. In-place edits (label_list.add/remove) are dropped; assign instead.
  def discard_unassigned_label_list
    @label_list = nil unless label_list_changed?
  end
end
