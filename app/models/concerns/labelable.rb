module Labelable
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :labels
    before_save :clear_labels_cache
  end

  def update_labels(labels = nil)
    update!(label_list: labels)
  end

  def add_labels(new_labels = nil)
    new_labels << labels
    update!(label_list: new_labels)
  end

  def preloaded_label_list
    unless @labels_cache
      @labels_cache = []
      taggings.each do |tagging|
        @labels_cache << tagging.tag.name
      end
    end

    @labels_cache || []
  end

  private

  def clear_labels_cache
    @labels_cache = nil
  end
end
