# frozen_string_literal: true

module ActsAsTaggableOn
  module TagsHelper
    # See the wiki for an example using tag_cloud.
    def tag_cloud(tags, classes)
      return [] if tags.empty?

      max_count = tags.max_by(&:taggings_count).taggings_count.to_f

      tags.each do |tag|
        index = ((tag.taggings_count / max_count) * (classes.size - 1))
        yield tag, classes[index.nan? ? 0 : index.round]
      end
    end
  end
end
