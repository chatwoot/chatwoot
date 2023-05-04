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

  def preloaded_label_list
    unless @taggings_cache
      @taggings_cache = []
      taggings.each do |tagging|
        @taggings_cache << tagging.tag.name
      end
    end

    @taggings_cache || []
  end
end
