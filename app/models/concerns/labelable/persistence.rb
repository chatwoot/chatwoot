module Labelable::Persistence
  # acts-as-taggable-on persists any loaded tag list, even when a save only changes
  # unrelated fields. A conversation broadcast can load an empty list before an
  # automation adds labels in another worker; saving first-reply fields on the stale
  # instance then deletes those labels without a tracked label change or removal activity.
  # Compare against a copy of the original list to protect both taggings and their cache
  # while preserving in-place label_list.add/remove edits that bypass the setter.
  def tag_list_cache_on(context)
    super.tap do |list|
      @original_tag_lists ||= {}
      @original_tag_lists[context.to_s] ||= list.dup
    end
  end

  # Both tagging and cache callbacks use this gate. Reading a list must not let an
  # unrelated save overwrite another worker's labels, but in-place edits must persist.
  def tag_list_cache_set_on(context)
    super && tag_list_cache_on(context) != @original_tag_lists.fetch(context.to_s)
  end

  def save_tags
    super.tap do
      @original_tag_lists&.each_key do |context|
        @original_tag_lists[context] = tag_list_cache_on(context).dup
      end
    end
  end

  def reload(*)
    @original_tag_lists = nil
    super
  end
end
