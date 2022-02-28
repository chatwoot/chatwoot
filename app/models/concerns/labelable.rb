module Labelable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :labels
  end

  def update_labels(labels = nil)
    update!(label_list: labels)
  end

  def add_labels(new_labels = nil)
    new_labels << labels
    update!(label_list: new_labels)
  end

  def add_automation_labels(new_labels = nil)
    new_labels << labels if labels.any?
    update(label_list: new_labels)
  end
end
