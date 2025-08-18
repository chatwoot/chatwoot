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
end
