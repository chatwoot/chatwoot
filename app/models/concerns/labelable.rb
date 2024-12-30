module Labelable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :labels
  end

  def update_labels(labels = nil)
    update!(label_list: labels)
  end

  def add_labels(new_labels = nil)
    new_labels = Array(new_labels) # Make sure new_labels is an array
    combined_labels = labels + new_labels
    update!(label_list: combined_labels)
  end

  def remove_labels_if_present(labels_to_remove = nil)
    Rails.logger.info("Removing labels: #{labels_to_remove}")
    labels_to_remove = Array(labels_to_remove) # Make sure labels_to_remove is an array
    Rails.logger.info("Labels to remove: #{labels_to_remove}")
    remaining_labels = labels - labels_to_remove
    Rails.logger.info("Remaining labels: #{remaining_labels}")
    update!(label_list: remaining_labels)
  end
end
